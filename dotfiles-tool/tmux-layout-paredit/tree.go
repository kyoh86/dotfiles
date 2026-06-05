package main

import (
	"strconv"
	"strings"
)

func copyNode(n Node) Node {
	if n.Type() == "leaf" {
		leaf := n.AsLeaf()
		return NewLeaf(leaf.Pane, Rect{X: leaf.Rect.X, Y: leaf.Rect.Y, W: leaf.Rect.W, H: leaf.Rect.H})
	}
	split := n.AsSplit()
	children := make([]Node, len(split.Children))
	for i, c := range split.Children {
		children[i] = copyNode(c)
	}
	return NewSplit(split.Axis, Rect{X: split.Rect.X, Y: split.Rect.Y, W: split.Rect.W, H: split.Rect.H}, children)
}

func swapChildren(root Node, path []int) Node {
	newRoot := copyNode(root)

	// Navigate to path
	current := newRoot
	for _, i := range path {
		if current.Type() == "leaf" {
			return newRoot
		}
		split := current.AsSplit()
		current = split.Children[i]
	}

	if current.Type() == "leaf" {
		return newRoot
	}

	split := current.AsSplit()
	split.Children[0], split.Children[1] = split.Children[1], split.Children[0]

	return newRoot
}

func recalculateRects(node Node, parentRect *Rect) Node {
	if node.Type() == "leaf" {
		leaf := node.AsLeaf()
		if parentRect != nil {
			return NewLeaf(leaf.Pane, Rect{X: parentRect.X, Y: parentRect.Y, W: leaf.Rect.W, H: leaf.Rect.H})
		}
		return node
	}

	split := node.AsSplit()
	rect := split.Rect
	if parentRect != nil {
		rect.X = parentRect.X
		rect.Y = parentRect.Y
	}

	var updatedChildren []Node
	if split.Axis == AxisRow {
		leftRect := Rect{W: getRect(split.Children[0]).W, H: rect.H, X: rect.X, Y: rect.Y}
		updatedChildren = append(updatedChildren, recalculateRects(split.Children[0], &leftRect))
		rightRect := Rect{W: getRect(split.Children[1]).W, H: rect.H, X: rect.X + getRect(split.Children[0]).W + 1, Y: rect.Y}
		updatedChildren = append(updatedChildren, recalculateRects(split.Children[1], &rightRect))
		rect.W = getRect(split.Children[0]).W + 1 + getRect(split.Children[1]).W
	} else {
		leftRect := Rect{W: rect.W, H: getRect(split.Children[0]).H, X: rect.X, Y: rect.Y}
		updatedChildren = append(updatedChildren, recalculateRects(split.Children[0], &leftRect))
		rightRect := Rect{W: rect.W, H: getRect(split.Children[1]).H, X: rect.X, Y: rect.Y + getRect(split.Children[0]).H + 1}
		updatedChildren = append(updatedChildren, recalculateRects(split.Children[1], &rightRect))
		rect.H = getRect(split.Children[0]).H + 1 + getRect(split.Children[1]).H
	}

	return NewSplit(split.Axis, rect, updatedChildren)
}

func leafPanes(leaves []*Leaf) string {
	panes := make([]string, len(leaves))
	for i, l := range leaves {
		panes[i] = l.Pane
	}
	return strings.Join(panes, ", ")
}

func flipSelected(root Node, state *State) error {
	n := nodeAt(root, state.SelectedPath)
	if n.Type() == "leaf" {
		return nil
	}

	log("flip: selected node is " + compact(n))
	log("flip: === BEFORE FLIP ===")
	logPaneContents()

	split := n.AsSplit()
	leftLeaves := leaves(split.Children[0])
	rightLeaves := leaves(split.Children[1])

	log("flip: left subtree (" + strconv.Itoa(len(leftLeaves)) + " leaves): " + leafPanes(leftLeaves))
	log("flip: right subtree (" + strconv.Itoa(len(rightLeaves)) + " leaves): " + leafPanes(rightLeaves))

	newRoot := swapChildren(root, state.SelectedPath)
	newN := nodeAt(newRoot, state.SelectedPath)
	if newN.Type() == "leaf" {
		return nil
	}

	newSplit := newN.AsSplit()
	log("flip: structure after: left=" + compact(newSplit.Children[0]) + ", right=" + compact(newSplit.Children[1]))

	if err := applyLayout(newRoot, nil); err != nil {
		return err
	}

	allLeaves := append(append([]*Leaf{}, leftLeaves...), rightLeaves...)
	newLeftLeaves := leaves(newSplit.Children[0])
	newRightLeaves := leaves(newSplit.Children[1])
	newLeaves := append(append([]*Leaf{}, newLeftLeaves...), newRightLeaves...)

	targetAt := make([]int, len(allLeaves))
	for i, leaf := range allLeaves {
		paneID := leaf.Pane
		targetIdx := -1
		for j, nl := range newLeaves {
			if nl.Pane == paneID {
				targetIdx = j
				break
			}
		}
		targetAt[i] = targetIdx
	}

	targetStrs := make([]string, len(allLeaves))
	for i, t := range targetAt {
		targetStrs[i] = allLeaves[i].Pane + "->pos" + strconv.Itoa(t)
	}
	log("flip: target mapping: " + strings.Join(targetStrs, ", "))

	visited := make(map[int]bool)
	for i := range allLeaves {
		if visited[i] {
			continue
		}
		cycle := []int{}
		current := i
		for current != -1 && !visited[current] && targetAt[current] != -1 {
			cycle = append(cycle, current)
			visited[current] = true
			next := targetAt[current]
			if len(cycle) > 0 && next == cycle[0] {
				break
			}
			current = next
		}

		if len(cycle) > 1 {
			cycleStrs := make([]string, len(cycle))
			for i, c := range cycle {
				cycleStrs[i] = allLeaves[c].Pane
			}
			log("flip: cycle: " + strings.Join(cycleStrs, " -> "))

			tempPane := allLeaves[cycle[len(cycle)-1]].Pane
			for j := len(cycle) - 1; j > 0; j-- {
				fromPane := allLeaves[cycle[j-1]].Pane
				log("flip: swap " + fromPane + " -> " + tempPane)
				swapPane(fromPane, tempPane)
			}
		}
	}

	log("flip: === AFTER FLIP ===")
	logPaneContents()
	log("flip: done")
	return nil
}
