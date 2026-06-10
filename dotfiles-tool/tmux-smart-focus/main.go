package main

import (
	"fmt"
	"os"
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
	return err
}

func tmux(args ...string) (string, error) {
	baseArgs := []string{"tmux"}
	baseArgs = append(baseArgs, args...)
	return execCommand(baseArgs...)
}
