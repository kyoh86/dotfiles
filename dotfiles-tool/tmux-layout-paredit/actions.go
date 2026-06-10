package main

import "strconv"

type Actions struct {
	root  Node
	state *State
}

func NewActions(root Node, state *State) Actions {
	return Actions{root: root, state: state}
}

func (a Actions) Enter() error {
	pane, err := currentPane()
	if err != nil {
		return err
	}
	a.state.SelectedPath = pathOfPane(a.root, pane)
	return nil
}

func (a Actions) SelectFocus() error {
	return a.Enter()
}

func (a Actions) SelectParent() {
	if len(a.state.SelectedPath) > 0 {
		a.state.SelectedPath = parentPath(a.state.SelectedPath)
	}
}

func (a Actions) SelectChild(child int) {
	n := nodeAt(a.root, a.state.SelectedPath)
	if n.IsSplit() {
		newPath := append([]int{}, a.state.SelectedPath...)
		newPath = append(newPath, child)
		a.state.SelectedPath = newPath
	}
}

func (a Actions) SelectSibling() {
	a.state.SelectedPath = siblingPath(a.state.SelectedPath)
}

func (a Actions) Split(axis Axis) error {
	selected := nodeAt(a.root, a.state.SelectedPath)
	target := firstLeaf(selected).Pane

	flag := "-h"
	if axis == AxisCol {
		flag = "-v"
	}

	if _, err := tmux("split-window", flag, "-t", target, "-P", "-F", "#{pane_id}", "-c", "#{pane_current_path}", "-b"); err != nil {
		return err
	}

	newRoot, err := readTree()
	if err != nil {
		return err
	}

	pane, err := currentPane()
	if err != nil {
		return err
	}
	a.state.SelectedPath = pathOfPane(newRoot, pane)
	if err := saveState(a.state); err != nil {
		return err
	}
	return paint(newRoot, a.state)
}

func (a Actions) GrowChild(child int) error {
	n := nodeAt(a.root, a.state.SelectedPath)
	if n.IsLeaf() {
		return nil
	}

	split := n.AsSplit()
	axis := split.Axis

	// Get the target pane for the child to resize
	targetChild := split.Children[child]
	targetPane := firstLeaf(targetChild).Pane

	// Determine tmux resize flag based on axis
	// For row splits (horizontal), we resize left/right
	// For col splits (vertical), we resize up/down
	var direction string
	if axis == AxisRow {
		if child == 0 {
			direction = "-L" // Grow left (which is child 0)
		} else {
			direction = "-R" // Grow right (which is child 1)
		}
	} else {
		if child == 0 {
			direction = "-U" // Grow up (which is child 0)
		} else {
			direction = "-D" // Grow down (which is child 1)
		}
	}

	// Use tmux's native resize command
	if _, err := tmux("resize-pane", "-t", targetPane, direction, strconv.Itoa(Step)); err != nil {
		log("grow"+strconv.Itoa(child)+" failed: "+err.Error())
		return err
	}

	log("grow" + strconv.Itoa(child) + ": done")
	return nil
}
