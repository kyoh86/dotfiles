package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"reflect"
	"strings"
	"testing"
)

func TestDocBaseTemplateAndSave(t *testing.T) {
	post := `{"id":17,"title":"For %{me}","body":"Draft","scope":"group","tags":[{"name":"template"}],"groups":[{"id":5,"name":"Team"}]}`
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("X-DocBaseToken") != "fixture" {
			t.Error("missing DocBase authentication")
		}
		switch r.Method + " " + r.URL.Path {
		case "GET /posts/17":
			w.Write([]byte(post))
		case "GET /profile":
			w.Write([]byte(`{"name":"Tester"}`))
		case "GET /groups":
			w.Write([]byte(`[{"id":5,"name":"Team"}]`))
		case "POST /posts":
			var data map[string]any
			if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
				t.Error(err)
			}
			if data["title"] != "For Tester" || !reflect.DeepEqual(data["groups"], []any{float64(5)}) || data["notice"] != false {
				t.Errorf("unexpected create payload: %v", data)
			}
			w.Write([]byte(`{"id":42,"title":"For Tester","body":"Draft","scope":"group","groups":[{"id":5,"name":"Team"}]}`))
		case "GET /posts/42":
			w.Write([]byte(`{"id":42,"title":"For Tester","body":"Draft","scope":"group","groups":[{"id":5,"name":"Team"}]}`))
		case "PATCH /posts/42":
			var data map[string]any
			if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
				t.Error(err)
			}
			if !reflect.DeepEqual(data, map[string]any{"body": "Edited", "notice": false}) {
				t.Errorf("unexpected patch payload: %v", data)
			}
			w.Write([]byte(`{"id":42,"title":"For Tester","body":"Edited","scope":"group","groups":[{"id":5,"name":"Team"}]}`))
		default:
			t.Errorf("unexpected request: %s %s", r.Method, r.URL.Path)
			w.WriteHeader(http.StatusNotFound)
		}
	}))
	defer server.Close()
	c := client{baseURL: server.URL, credentials: credentials{Token: "fixture"}, http: server.Client()}
	template, err := readPost(c, options{template: "17"})
	if err != nil || template.Fields.Title != "For Tester" || len(template.Fields.Tags) != 0 {
		t.Fatalf("template: %+v, %v", template, err)
	}
	encoded, err := json.Marshal(template)
	if err != nil {
		t.Fatal(err)
	}
	saved, err := writePost(c, "", strings.NewReader(string(encoded)))
	if err != nil || saved.ID != "42" {
		t.Fatalf("create: %+v, %v", saved, err)
	}
	edited := saved.Fields
	edited.Body = "Edited"
	patch, err := json.Marshal(map[string]postFields{"original": saved.Fields, "fields": edited})
	if err != nil {
		t.Fatal(err)
	}
	saved, err = writePost(c, "42", strings.NewReader(string(patch)))
	if err != nil || saved.Fields.Body != "Edited" {
		t.Fatalf("patch: %+v, %v", saved, err)
	}
	_, err = writePost(c, "42", strings.NewReader(`{"original":{"body":"outdated"}}`))
	if err == nil || !strings.Contains(err.Error(), "changed remotely") {
		t.Fatalf("expected conflict, got %v", err)
	}
}

func TestInkdropPreservesRevisionAndUnknownFields(t *testing.T) {
	writes := 0
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		user, password, ok := r.BasicAuth()
		if !ok || user != "user" || password != "pass" {
			t.Error("missing Inkdrop authentication")
		}
		switch r.Method + " " + r.URL.Path {
		case "GET /note:fixture":
			w.Write([]byte(`{"_id":"note:fixture","_rev":"4-current","title":"Note","body":"remote","tags":["tag:old"],"other":9007199254740993}`))
		case "POST /notes":
			writes++
			var data map[string]json.RawMessage
			if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
				t.Error(err)
			}
			for key, value := range map[string]string{"_rev": `"4-current"`, "body": `"remote"`, "other": "9007199254740993", "tags": `["tag:old","tag:new"]`} {
				if string(data[key]) != value {
					t.Errorf("%s: got %s, expected %s", key, data[key], value)
				}
			}
			w.Write([]byte(`{"ok":true,"id":"note:fixture"}`))
		default:
			t.Errorf("unexpected request: %s %s", r.Method, r.URL.Path)
			w.WriteHeader(http.StatusNotFound)
		}
	}))
	defer server.Close()
	state := t.TempDir()
	opts := options{service: "inkdrop", id: "note:fixture", resource: "metadata"}
	path, err := opts.credentialPath(state)
	if err != nil {
		t.Fatal(err)
	}
	if err := saveCredentials(path, credentials{BaseURL: server.URL, Username: "user", Password: "pass"}); err != nil {
		t.Fatal(err)
	}
	result, err := run(opts, state, strings.NewReader(`{"action":"add_tag","value":"tag:new"}`))
	if err != nil {
		t.Fatal(err)
	}
	if got := result.(noteDocument).Metadata.Tags; !reflect.DeepEqual(got, []string{"tag:old", "tag:new"}) {
		t.Fatalf("tags: %v", got)
	}
	opts.resource = "write"
	_, err = run(opts, state, strings.NewReader(`{"original":{"title":"Note","body":"stale"}}`))
	if err == nil || !strings.Contains(err.Error(), "changed remotely") || writes != 1 {
		t.Fatalf("conflict: %v, writes: %d", err, writes)
	}
}
