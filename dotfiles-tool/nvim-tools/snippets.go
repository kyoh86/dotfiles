package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/pelletier/go-toml/v2"
)

func compileSnippets(path string, dirs []string) error {
	stem := strings.TrimSuffix(filepath.Base(path), ".toml")
	if i := strings.LastIndexByte(stem, '.'); i >= 0 {
		stem = stem[i+1:]
	}
	if stem == "" || filepath.Ext(path) != ".toml" {
		return fmt.Errorf("expected a snippet TOML path")
	}

	snippets := map[string]any{}
	// Apply each base file before its shards. ReadDir sorts shards by name.
	for _, dir := range dirs {
		entries, err := os.ReadDir(dir)
		if errors.Is(err, os.ErrNotExist) {
			continue
		}
		if err != nil {
			return err
		}
		for _, entry := range entries {
			name := entry.Name()
			if !entry.IsDir() && name == stem+".toml" {
				if err := mergeTOML(snippets, filepath.Join(dir, name)); err != nil {
					return err
				}
				break
			}
		}
		for _, entry := range entries {
			if !entry.IsDir() && strings.HasSuffix(entry.Name(), "."+stem+".toml") {
				if err := mergeTOML(snippets, filepath.Join(dir, entry.Name())); err != nil {
					return err
				}
			}
		}
	}

	var output bytes.Buffer
	encoder := json.NewEncoder(&output)
	encoder.SetEscapeHTML(false)
	encoder.SetIndent("", "    ")
	if err := encoder.Encode(snippets); err != nil {
		return err
	}
	target := filepath.Join(dirs[0], stem+".json")
	return writeFile(target, bytes.TrimSuffix(output.Bytes(), []byte("\n")))
}

func mergeTOML(snippets map[string]any, path string) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	var source map[string]any
	if err := toml.Unmarshal(data, &source); err != nil {
		return fmt.Errorf("%s: %w", path, err)
	}
	for key, value := range source {
		snippets[key] = value
	}
	return nil
}

func decompileSnippets(path string, input io.Reader) error {
	if filepath.Ext(path) != ".json" {
		return fmt.Errorf("expected a snippet JSON path")
	}
	decoder := json.NewDecoder(input)
	decoder.UseNumber()
	var snippets map[string]any
	if err := decoder.Decode(&snippets); err != nil {
		return err
	}
	if err := decoder.Decode(new(any)); err != io.EOF {
		return fmt.Errorf("expected a single JSON object")
	}
	if snippets == nil {
		return fmt.Errorf("expected a snippet JSON object")
	}
	converted, err := tomlValues(snippets)
	if err != nil {
		return err
	}
	data, err := toml.Marshal(converted)
	if err != nil {
		return err
	}
	return writeFile(strings.TrimSuffix(path, ".json")+".toml", data)
}

func tomlValues(value any) (any, error) {
	switch v := value.(type) {
	case nil:
		return nil, fmt.Errorf("TOML has no null value")
	case json.Number:
		if strings.ContainsAny(v.String(), ".eE") {
			return v.Float64()
		}
		return v.Int64()
	case map[string]any:
		for key, entry := range v {
			converted, err := tomlValues(entry)
			if err != nil {
				return nil, fmt.Errorf("%s: %w", key, err)
			}
			v[key] = converted
		}
	case []any:
		for index, entry := range v {
			converted, err := tomlValues(entry)
			if err != nil {
				return nil, err
			}
			v[index] = converted
		}
	}
	return value, nil
}

func writeFile(path string, data []byte) error {
	if resolved, err := filepath.EvalSymlinks(path); err == nil {
		path = resolved
	} else if !errors.Is(err, os.ErrNotExist) {
		return err
	}
	mode := os.FileMode(0644)
	if info, err := os.Stat(path); err == nil {
		if !info.Mode().IsRegular() {
			return fmt.Errorf("not a regular file: %s", path)
		}
		mode = info.Mode().Perm()
	} else if !errors.Is(err, os.ErrNotExist) {
		return err
	}
	file, err := os.CreateTemp(filepath.Dir(path), ".snippet-*")
	if err != nil {
		return err
	}
	defer os.Remove(file.Name())
	if err := file.Chmod(mode); err != nil {
		file.Close()
		return err
	}
	_, writeErr := file.Write(data)
	if err := errors.Join(writeErr, file.Close()); err != nil {
		return err
	}
	return os.Rename(file.Name(), path)
}
