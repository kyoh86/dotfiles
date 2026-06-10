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

	// Get current sizes
	size0 := totalSize(split.Children[0], axis)
	size1 := totalSize(split.Children[1], axis)

	if size0 == 0 || size1 == 0 {
		return nil
	}

	var newSize0, newSize1 int
	if child == 0 {
		newSize0 = size0 + Step
		newSize1 = size1 - Step
		if newSize1 < 1 {
			newSize1 = 1
			newSize0 = size0 + size1 - 1
		}
	} else {
		newSize0 = size0 - Step
		newSize1 = size1 + Step
		if newSize0 < 1 {
			newSize0 = 1
			newSize1 = size0 + size1 - 1
		}
	}

	// Resize children
	newChild0 := resizeTotal(split.Children[0], axis, newSize0)
	newChild1 := resizeTotal(split.Children[1], axis, newSize1)

	// Create new parent node with resized children
	newParent := NewSplit(split.Axis, split.Rect, []Node{newChild0, newChild1})

	// Replace the parent in the tree
	newRoot := modifyNodeAtPath(a.root, a.state.SelectedPath, func(s *Split) {
		s.Children[0] = newParent.AsSplit().Children[0]
		s.Children[1] = newParent.AsSplit().Children[1]
	})

	// Apply the new layout
	if err := applyLayout(newRoot, nil); err != nil {
		log("grow" + strconv.Itoa(child) + " failed: " + err.Error())
		return err
	}

	log("grow" + strconv.Itoa(child) + ": done")
	return nil
}
