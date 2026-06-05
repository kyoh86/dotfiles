package main

import (
	"fmt"
	"os"
	"runtime/debug"
)

func run() error {
	cmd := "paint"
	if len(os.Args) > 1 {
		cmd = os.Args[1]
	}
	log("main: cmd=" + cmd)

	root, err := readTree()
	if err != nil {
		return fmt.Errorf("readTree failed: %w", err)
	}

	state, err := loadState()
	if err != nil {
		return fmt.Errorf("loadState failed: %w", err)
	}

	switch cmd {
	case "enter":
		pane, err := currentPane()
		if err != nil {
			return fmt.Errorf("currentPane failed: %w", err)
		}
		state.SelectedPath = pathOfPane(root, pane)
		state.Preselect = nil

	case "select-focus":
		pane, err := currentPane()
		if err != nil {
			return fmt.Errorf("currentPane failed: %w", err)
		}
		state.SelectedPath = pathOfPane(root, pane)

	case "parent":
		if len(state.SelectedPath) > 0 {
			state.SelectedPath = parentPath(state.SelectedPath)
		}

	case "child0":
		n := nodeAt(root, state.SelectedPath)
		if n.Type() == "split" {
			newPath := append([]int{}, state.SelectedPath...)
			newPath = append(newPath, 0)
			state.SelectedPath = newPath
		}

	case "child1":
		n := nodeAt(root, state.SelectedPath)
		if n.Type() == "split" {
			newPath := append([]int{}, state.SelectedPath...)
			newPath = append(newPath, 1)
			state.SelectedPath = newPath
		}

	case "sibling":
		state.SelectedPath = siblingPath(state.SelectedPath)

	case "pre-v":
		selected := nodeAt(root, state.SelectedPath)
		if selected.Type() == "split" {
			tmuxIgnoreError("display-message", "preselect: only available on single pane (use u/1/2 to select a leaf)")
			saveState(state)
			paint(root, state)
			return nil
		}
		axis := AxisRow
		state.Preselect = &axis

	case "pre-s":
		selected := nodeAt(root, state.SelectedPath)
		if selected.Type() == "split" {
			tmuxIgnoreError("display-message", "preselect: only available on single pane (use u/1/2 to select a leaf)")
			saveState(state)
			paint(root, state)
			return nil
		}
		axis := AxisCol
		state.Preselect = &axis

	case "cancel":
		state.Preselect = nil

	case "split":
		if err := splitSelected(root, state); err != nil {
			return fmt.Errorf("splitSelected failed: %w", err)
		}
		return nil

	case "flip":
		if err := flipSelected(root, state); err != nil {
			return fmt.Errorf("flipSelected failed: %w", err)
		}

	case "grow0":
		if err := growChild(root, state, 0); err != nil {
			return fmt.Errorf("growChild failed: %w", err)
		}

	case "grow1":
		if err := growChild(root, state, 1); err != nil {
			return fmt.Errorf("growChild failed: %w", err)
		}

	case "paint":
		// Just paint the current state
		return nil

	case "clear":
		clearStyles()
		state.Preselect = nil
		state.SelectedPath = []int{}
		saveState(state)
		return nil

	default:
		log("main: unknown command: " + cmd)
		return nil
	}

	if err := saveState(state); err != nil {
		return fmt.Errorf("saveState failed: %w", err)
	}

	updatedRoot, err := readTree()
	if err != nil {
		return fmt.Errorf("readTree failed: %w", err)
	}

	if err := paint(updatedRoot, state); err != nil {
		return fmt.Errorf("paint failed: %w", err)
	}
	return nil
}

func main() {
	defer func() {
		if r := recover(); r != nil {
			stack := debug.Stack()
			tmuxIgnoreError("display-message", "layout-paredit panic: "+fmt.Sprint(r))
			log("panic: "+fmt.Sprint(r))
			log(string(stack))
			fmt.Fprintln(os.Stderr, "panic:", r)
			fmt.Fprintln(os.Stderr, string(stack))
			os.Exit(1)
		}
	}()
	if err := run(); err != nil {
		tmuxIgnoreError("display-message", "layout-paredit error: "+err.Error())
		log(err.Error())
		fmt.Fprintln(os.Stderr, err.Error())
		os.Exit(1)
	}
}
