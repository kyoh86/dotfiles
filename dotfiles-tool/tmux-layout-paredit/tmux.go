package main

import (
	"fmt"
	"os/exec"
	"strings"
)

func tmux(args ...string) (string, error) {
	cmd := exec.Command("tmux", args...)
	out, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("tmux %s failed: %w", strings.Join(args, " "), err)
	}
	return strings.TrimRight(string(out), "\n"), nil
}

func tmuxIgnoreError(args ...string) {
	_, _ = tmux(args...)
}
