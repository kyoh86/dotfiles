package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

func TestFetchTitle(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/missing" {
			http.NotFound(w, r)
			return
		}
		w.Header().Set("Content-Type", "text/html; charset=iso-8859-1")
		w.Write([]byte("<html><head><title>  Caf\xe9 &amp;\n [a] </title></head></html>"))
	}))
	defer server.Close()
	got, err := fetchTitle(server.URL)
	if err != nil || got != "Café & [a]" {
		t.Fatalf("title = %q, %v", got, err)
	}
	if _, err := fetchTitle(server.URL + "/missing"); err == nil {
		t.Fatal("expected HTTP error")
	}
}

func TestSnippetMergeAndRoundTrip(t *testing.T) {
	primary, secondary := t.TempDir(), t.TempDir()
	paths := map[string]string{
		filepath.Join(primary, "lua.toml"):        "[one]\nprefix = 'one'\nbody = ['a', 'b']\n",
		filepath.Join(primary, "a.lua.toml"):      "[two]\nprefix = ['two', '2']\nbody = '${1:<text>}'\n",
		filepath.Join(secondary, "z.lua.toml"):    "[one]\nprefix = 'one'\nbody = ['changed', 'b']\n",
		filepath.Join(secondary, "other.go.toml"): "invalid",
	}
	for path, text := range paths {
		if err := os.WriteFile(path, []byte(text), 0600); err != nil {
			t.Fatal(err)
		}
	}
	target := filepath.Join(primary, "lua.json")
	if err := compileSnippets(filepath.Join(primary, "a.lua.toml"), []string{primary, secondary}); err != nil {
		t.Fatal(err)
	}
	data, err := os.ReadFile(target)
	if err != nil {
		t.Fatal(err)
	}
	var got map[string]map[string]any
	if err := json.Unmarshal(data, &got); err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(got["one"]["body"], []any{"changed", "b"}) || got["two"]["body"] != "${1:<text>}" {
		t.Fatalf("unexpected merge: %s", data)
	}

	roundTrip := t.TempDir()
	if err := decompileSnippets(filepath.Join(roundTrip, "lua.json"), strings.NewReader(string(data))); err != nil {
		t.Fatal(err)
	}
	if err := compileSnippets(filepath.Join(roundTrip, "lua.toml"), []string{roundTrip}); err != nil {
		t.Fatal(err)
	}
	recompiled, err := os.ReadFile(filepath.Join(roundTrip, "lua.json"))
	if err != nil || string(recompiled) != string(data) {
		t.Fatalf("round trip: %s, %v", recompiled, err)
	}

	if err := os.WriteFile(filepath.Join(primary, "broken.lua.toml"), []byte("["), 0600); err != nil {
		t.Fatal(err)
	}
	if err := compileSnippets(filepath.Join(primary, "lua.toml"), []string{primary}); err == nil {
		t.Fatal("expected invalid TOML error")
	}
	after, err := os.ReadFile(target)
	if err != nil || string(after) != string(data) {
		t.Fatalf("failed conversion altered output: %s, %v", after, err)
	}
}
