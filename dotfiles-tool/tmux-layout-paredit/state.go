package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

func currentWindowID() (string, error) {
	return tmux("display-message", "-p", "#{session_id}:#{window_id}")
}

func statePath() (string, error) {
	base := os.Getenv("XDG_RUNTIME_DIR")
	if base == "" {
		base = "/tmp"
	}
	id, err := currentWindowID()
	if err != nil {
		return "", err
	}
	reg := regexp.MustCompile(`[^A-Za-z0-9_.:\-]`)
	id = reg.ReplaceAllString(id, "_")
	return filepath.Join(base, "tmux-layout-paredit-"+id+".json"), nil
}

func loadState() (*State, error) {
	path, err := statePath()
	if err != nil {
		return nil, err
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return &State{SelectedPath: []int{}}, nil
	}
	var state State
	if err := json.Unmarshal(data, &state); err != nil {
		return &State{SelectedPath: []int{}}, nil
	}
	return &state, nil
}

func saveState(state *State) error {
	path, err := statePath()
	if err != nil {
		return err
	}
	data, err := json.Marshal(state)
	if err != nil {
		return err
	}
	return os.WriteFile(path, data, 0644)
}

func readTree() (Node, error) {
	layout, err := tmux("display-message", "-p", "#{window_layout}")
	if err != nil {
		return Node{}, err
	}
	parsed, err := parseLayout(layout)
	if err != nil {
		return Node{}, err
	}
	return normalizeToBinary(parsed), nil
}

func currentPane() (string, error) {
	return tmux("display-message", "-p", "#{pane_id}")
}

func log(msg string) error {
	base := os.Getenv("XDG_RUNTIME_DIR")
	if base == "" {
		base = "/tmp"
	}
	path := filepath.Join(base, "tmux-layout-paredit-_0:_0.log")
	f, err := os.OpenFile(path, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return err
	}
	defer f.Close()
	_, err = f.WriteString("[" + time.Now().Format(time.RFC3339) + "] " + msg + "\n")
	return err
}

func logPaneContents() error {
	panesStr, err := tmux("list-panes", "-F", "#{pane_id}")
	if err != nil {
		return err
	}
	panes := strings.SplitSeq(panesStr, "\n")
	for pane := range panes {
		if pane == "" {
			continue
		}
		content, err := tmux("capture-pane", "-p", "-t", pane, "-C", "-J")
		if err != nil {
			log("failed to capture pane " + pane + ": " + err.Error())
			continue
		}
		lines := strings.Split(content, "\n")
		preview := ""
		if len(lines) > 0 {
			preview = regexp.MustCompile(`\x1b\[.*?m`).ReplaceAllString(lines[0], "")
		}
		if len(preview) > 50 {
			preview = preview[:50]
		}
		log("pane " + pane + ": " + preview)
	}
	return nil
}
