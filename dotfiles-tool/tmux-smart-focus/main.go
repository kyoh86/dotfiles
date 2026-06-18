package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "Usage: tmux-smart-focus <h|j|k|l>")
		os.Exit(1)
	}

	direction := os.Args[1]

	switch direction {
	case "h", "j", "k", "l":
		// Valid directions
	default:
		fmt.Fprintln(os.Stderr, "Invalid direction. Use h, j, k, or l")
		os.Exit(1)
	}

	err := smartFocus(direction)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

func smartFocus(direction string) error {
	// Map vim direction to tmux direction flag
	tmuxDir := map[string]string{
		"h": "-L", // left
		"j": "-D", // down
		"k": "-U", // up
		"l": "-R", // right
	}[direction]

	// Simply move to adjacent pane
	_, err := tmux("select-pane", tmuxDir)
	if err != nil {
		return err
	}
	if isCurrentPaneNvim() {
		_ = focusNvimEdge(direction)
	}
	return nil
}

func isCurrentPaneNvim() bool {
	out, err := tmux("display-message", "-p", "#{pane_current_command}")
	if err != nil {
		return false
	}
	return strings.TrimSpace(out) == "nvim"
}

func focusNvimEdge(direction string) error {
	if err := focusNvimEdgeByServer(direction); err == nil {
		return nil
	}
	return focusNvimEdgeByProxy(direction)
}

func focusNvimEdgeByServer(direction string) error {
	serverName := lookupTmuxEnv("NVIM_SERVER_NAME")
	if serverName == "" {
		return fmt.Errorf("NVIM_SERVER_NAME is not set")
	}
	expr := fmt.Sprintf(`luaeval("require('kyoh86.lib.tmux').focus_edge(_A)", "%s")`, direction)
	_, err := execCommand("nvim", "--server", serverName, "--remote-expr", expr)
	return err
}

func lookupTmuxEnv(name string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	out, err := tmux("show-environment", "-g", name)
	if err != nil {
		return ""
	}
	prefix := name + "="
	for _, line := range strings.Split(out, "\n") {
		if strings.HasPrefix(line, prefix) {
			return strings.TrimPrefix(line, prefix)
		}
	}
	return ""
}

func focusNvimEdgeByProxy(direction string) error {
	proxyURL := lookupTmuxEnv("NVIM_PROXY_URL")
	pid := lookupTmuxEnv("NVIM_PID")
	if proxyURL == "" || pid == "" {
		return nil
	}
	body, err := json.Marshal(map[string]string{"direction": direction})
	if err != nil {
		return err
	}
	req, err := http.NewRequest(http.MethodPost, strings.TrimRight(proxyURL, "/")+"/focus-edge", bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("content-type", "application/json")
	req.Header.Set("X-Nvim-Pid", pid)
	client := http.Client{Timeout: time.Second}
	res, err := client.Do(req)
	if err != nil {
		return err
	}
	defer res.Body.Close()
	if res.StatusCode < 200 || res.StatusCode >= 300 {
		return fmt.Errorf("focus-edge failed: %s", res.Status)
	}
	return nil
}

func tmux(args ...string) (string, error) {
	baseArgs := []string{"tmux"}
	baseArgs = append(baseArgs, args...)
	return execCommand(baseArgs...)
}
