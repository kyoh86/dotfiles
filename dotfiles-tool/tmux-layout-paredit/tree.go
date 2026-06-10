package main

import (
	"fmt"
	"strconv"
	"strings"
)

func copyNode(n Node) Node {
	if n.IsLeaf() {
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
	return modifyNodeAtPath(root, path, func(split *Split) {
		split.Children[0], split.Children[1] = split.Children[1], split.Children[0]
	})
}

func setAxisAt(root Node, path []int, axis Axis) Node {
	return modifyNodeAtPath(root, path, func(split *Split) {
		split.Axis = axis
	})
}

func swapChildrenAndSetAxis(root Node, path []int, axis Axis) Node {
	return modifyNodeAtPath(root, path, func(split *Split) {
		split.Children[0], split.Children[1] = split.Children[1], split.Children[0]
		split.Axis = axis
	})
}

func modifyNodeAtPath(root Node, path []int, modifier func(*Split)) Node {
	if len(path) == 0 {
		if root.IsLeaf() {
			return root
		}
		split := root.AsSplit()
		newSplit := NewSplit(split.Axis, split.Rect, copyNodes(split.Children))
		modifier(newSplit.AsSplit())
		return newSplit
	}

	newRoot := copyNode(root)
	current := newRoot
	for idx, i := range path {
		if current.IsLeaf() {
			return newRoot
		}
		split := current.AsSplit()
		if i >= len(split.Children) {
			return newRoot
		}
		if idx == len(path)-1 {
			child := split.Children[i]
			if child.IsLeaf() {
				return newRoot
			}
			childSplit := child.AsSplit()
			newChild := NewSplit(childSplit.Axis, childSplit.Rect, copyNodes(childSplit.Children))
			modifier(newChild.AsSplit())
			split.Children[i] = newChild
			return newRoot
		}
		current = split.Children[i]
	}
	return newRoot
}

func copyNodes(nodes []Node) []Node {
	result := make([]Node, len(nodes))
	for i, n := range nodes {
		result[i] = copyNode(n)
	}
	return result
}

// setNodePositionRecursive sets positions for all nodes in a tree
func setNodePositionRecursive(node Node, x, y int) Node {
	if node.IsLeaf() {
		leaf := node.AsLeaf()
		return NewLeaf(leaf.Pane, Rect{X: x, Y: y, W: leaf.Rect.W, H: leaf.Rect.H})
	}
	split := node.AsSplit()
	newRect := Rect{X: x, Y: y, W: split.Rect.W, H: split.Rect.H}

	var updatedChildren []Node
	if split.Axis == AxisRow {
		childX := x
		for _, child := range split.Children {
			newChild := setNodePositionRecursive(child, childX, y)
			updatedChildren = append(updatedChildren, newChild)
			childX += getRect(newChild).W + 1
		}
	} else {
		childY := y
		for _, child := range split.Children {
			newChild := setNodePositionRecursive(child, x, childY)
			updatedChildren = append(updatedChildren, newChild)
			childY += getRect(newChild).H + 1
		}
	}

	return NewSplit(split.Axis, newRect, updatedChildren)
}

// normalizeSizes normalizes the sizes of children in a split node
// For row splits, all children get the same height, width is distributed proportionally
// For col splits, all children get the same width, height is distributed proportionally
func normalizeSizes(node Node, width, height int) Node {
	if node.IsLeaf() {
		leaf := node.AsLeaf()
		return NewLeaf(leaf.Pane, Rect{X: leaf.Rect.X, Y: leaf.Rect.Y, W: width, H: height})
	}

	split := node.AsSplit()
	numChildren := len(split.Children)
	var updatedChildren []Node

	if split.Axis == AxisRow {
		// For row splits: distribute width among children (they share height uniformly)
		// Total width = sum(child widths) + (numChildren - 1) separators
		// So sum(child widths) = width - (numChildren - 1)
		availableWidth := width - (numChildren - 1)
		if availableWidth < numChildren {
			availableWidth = numChildren // Ensure at least 1 width per child
		}

		// Distribute equally, then handle remainder
		baseWidth := availableWidth / numChildren
		remainder := availableWidth % numChildren

		for i, child := range split.Children {
			allocatedWidth := baseWidth
			if i < remainder {
				allocatedWidth++
			}
			updatedChildren = append(updatedChildren, normalizeSizes(child, allocatedWidth, height))
		}
	} else {
		// For col splits: distribute height among children (they share width uniformly)
		// Total height = sum(child heights) + (numChildren - 1) separators
		// So sum(child heights) = height - (numChildren - 1)
		availableHeight := height - (numChildren - 1)
		if availableHeight < numChildren {
			availableHeight = numChildren // Ensure at least 1 height per child
		}

		// Distribute equally, then handle remainder
		baseHeight := availableHeight / numChildren
		remainder := availableHeight % numChildren

		for i, child := range split.Children {
			allocatedHeight := baseHeight
			if i < remainder {
				allocatedHeight++
			}
			updatedChildren = append(updatedChildren, normalizeSizes(child, width, allocatedHeight))
		}
	}

	return NewSplit(split.Axis, Rect{X: split.Rect.X, Y: split.Rect.Y, W: width, H: height}, updatedChildren)
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
	if n.IsLeaf() {
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
	if newN.IsLeaf() {
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

func toggleAxis(root Node, state *State) error {
	n := nodeAt(root, state.SelectedPath)
	if n.IsLeaf() {
		return nil
	}

	split := n.AsSplit()
	oldAxis := split.Axis

	var newAxis Axis
	if oldAxis == AxisRow {
		newAxis = AxisCol
	} else {
		newAxis = AxisRow
	}

	log("toggle: axis " + string(oldAxis) + " -> " + string(newAxis))

	newRoot := setAxisAt(root, state.SelectedPath, newAxis)

	if err := applyLayout(newRoot, nil); err != nil {
		return err
	}

	log("toggle: done")
	return nil
}

func rotateSelected(root Node, state *State) error {
	n := nodeAt(root, state.SelectedPath)
	if n.IsLeaf() {
		return nil
	}

	log("rotate: selected path = " + fmt.Sprint(state.SelectedPath) + ", node = " + compact(n))

	split := n.AsSplit()
	oldAxis := split.Axis

	var newAxis Axis
	if oldAxis == AxisRow {
		newAxis = AxisCol
	} else {
		newAxis = AxisRow
	}

	log("rotate: axis " + string(oldAxis) + " -> " + string(newAxis))

	newRoot := swapChildrenAndSetAxis(root, state.SelectedPath, newAxis)
	log("rotate: after swap, root = " + compact(newRoot))

	if err := applyLayout(newRoot, nil); err != nil {
		return err
	}

	log("rotate: done")
	return nil
}
