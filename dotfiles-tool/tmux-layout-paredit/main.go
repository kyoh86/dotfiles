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
	actions := NewActions(root, state)

	switch cmd {
	case "enter":
		if err := actions.Enter(); err != nil {
			return fmt.Errorf("enter failed: %w", err)
		}

	case "select-focus":
		if err := actions.SelectFocus(); err != nil {
			return fmt.Errorf("selectFocus failed: %w", err)
		}

	case "parent":
		actions.SelectParent()

	case "child0":
		actions.SelectChild(0)

	case "child1":
		actions.SelectChild(1)

	case "sibling":
		actions.SelectSibling()

	case "split-v":
		if err := actions.Split(AxisRow); err != nil {
			return fmt.Errorf("split failed: %w", err)
		}
		return nil

	case "split-s":
		if err := actions.Split(AxisCol); err != nil {
			return fmt.Errorf("split failed: %w", err)
		}
		return nil

	case "flip":
		if err := flipSelected(root, state); err != nil {
			return fmt.Errorf("flipSelected failed: %w", err)
		}

	case "grow0":
		if err := actions.GrowChild(0); err != nil {
			return fmt.Errorf("growChild failed: %w", err)
		}

	case "grow1":
		if err := actions.GrowChild(1); err != nil {
			return fmt.Errorf("growChild failed: %w", err)
		}

	case "toggle":
		if err := toggleAxis(root, state); err != nil {
			return fmt.Errorf("toggleAxis failed: %w", err)
		}

	case "rotate":
		if err := rotateSelected(root, state); err != nil {
			return fmt.Errorf("rotateSelected failed: %w", err)
		}

	case "paint":
		// Just paint the current state
		return nil

	case "clear":
		clearStyles()
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
			log("panic: " + fmt.Sprint(r))
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
