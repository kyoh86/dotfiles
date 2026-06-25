package main

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

	newRoot, changed := growChildAtPath(a.root, a.state.SelectedPath, child, Step)
	if !changed {
		return nil
	}

	if err := applyLayoutPreserveSizes(newRoot, nil); err != nil {
		return err
	}
	log("grow: done")
	return nil
}
