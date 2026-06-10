package main

import (
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

// modifyNodeAtPath creates a copy of the tree and applies a modifier function to the split node at the given path
func modifyNodeAtPath(root Node, path []int, modifier func(*Split)) Node {
	if len(path) == 0 {
		// Modify root node directly
		if root.IsLeaf() {
			return root
		}
		split := root.AsSplit()
		// Create a new split with modified values
		newSplit := NewSplit(split.Axis, split.Rect, copyNodes(split.Children))
		modifier(newSplit.AsSplit())
		return newSplit
	}

	newRoot := copyNode(root)

	// Navigate to the target node
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
			// This is the last element - we're at the target
			child := split.Children[i]
			if child.IsLeaf() {
				return newRoot
			}
			childSplit := child.AsSplit()
			// Create a new split with modified values
			newChild := NewSplit(childSplit.Axis, childSplit.Rect, copyNodes(childSplit.Children))
			// Apply the modifier to the new child
			modifier(newChild.AsSplit())
			// Replace the child in the parent's children array
			split.Children[i] = newChild
			return newRoot
		}

		// Move to the next child
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

func recalculateRects(node Node, parentRect *Rect) Node {
	if node.IsLeaf() {
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
		rect.W = parentRect.W
		rect.H = parentRect.H
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

// totalSize calculates the total size of a subtree along the given axis
func totalSize(node Node, axis Axis) int {
	if node.IsLeaf() {
		leaf := node.AsLeaf()
		if axis == AxisRow {
			return leaf.Rect.W
		}
		return leaf.Rect.H
	}

	split := node.AsSplit()
	var total int
	for _, child := range split.Children {
		total += totalSize(child, axis)
	}
	return total
}

// resizeTotal resizes a subtree to a new total size along the given axis
// It preserves the relative proportions of leaf nodes
func resizeTotal(node Node, axis Axis, newTotal int) Node {
	if node.IsLeaf() {
		leaf := node.AsLeaf()
		if axis == AxisRow {
			return NewLeaf(leaf.Pane, Rect{X: leaf.Rect.X, Y: leaf.Rect.Y, W: newTotal, H: leaf.Rect.H})
		}
		return NewLeaf(leaf.Pane, Rect{X: leaf.Rect.X, Y: leaf.Rect.Y, W: leaf.Rect.W, H: newTotal})
	}

	split := node.AsSplit()
	currentTotal := totalSize(node, axis)
	if currentTotal == 0 {
		return node
	}

	// Calculate new sizes for children proportionally
	var updatedChildren []Node
	for _, child := range split.Children {
		childSize := totalSize(child, axis)
		newChildSize := int(float64(childSize) * float64(newTotal) / float64(currentTotal))
		if newChildSize < 1 {
			newChildSize = 1
		}
		updatedChildren = append(updatedChildren, resizeTotal(child, axis, newChildSize))
	}

	// Ensure the total matches exactly by adjusting the last child
	actualTotal := 0
	for _, child := range updatedChildren {
		actualTotal += totalSize(child, axis)
	}
	if len(updatedChildren) > 0 && actualTotal != newTotal {
		lastIdx := len(updatedChildren) - 1
		lastChild := updatedChildren[lastIdx]
		adjustedSize := totalSize(lastChild, axis) + (newTotal - actualTotal)
		updatedChildren[lastIdx] = resizeTotal(lastChild, axis, adjustedSize)
	}

	return NewSplit(split.Axis, split.Rect, updatedChildren)
}

// resizeChildAt resizes a child of a split node at the given path
func resizeChildAt(root Node, path []int, child int, amount int) Node {
	if len(path) == 0 {
		return root
	}

	parent := nodeAt(root, path)
	if parent.IsLeaf() {
		return root
	}

	split := parent.AsSplit()
	axis := split.Axis

	// Get current sizes
	size0 := totalSize(split.Children[0], axis)
	size1 := totalSize(split.Children[1], axis)

	if size0 == 0 || size1 == 0 {
		return root
	}

	var newSize0, newSize1 int
	if child == 0 {
		newSize0 = size0 + amount
		newSize1 = size1 - amount
		if newSize1 < 1 {
			newSize1 = 1
			newSize0 = size0 + size1 - 1
		}
	} else {
		newSize0 = size0 - amount
		newSize1 = size1 + amount
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
	return modifyNodeAtPath(root, path, func(s *Split) {
		s.Children[0] = newParent.AsSplit().Children[0]
		s.Children[1] = newParent.AsSplit().Children[1]
	})
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

	// Toggle axis
	var newAxis Axis
	if oldAxis == AxisRow {
		newAxis = AxisCol
	} else {
		newAxis = AxisRow
	}

	log("toggle: axis " + string(oldAxis) + " -> " + string(newAxis))

	// Create new tree with toggled axis
	newRoot := setAxisAt(root, state.SelectedPath, newAxis)

	// Apply layout with new axis
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

	split := n.AsSplit()
	oldAxis := split.Axis

	// Rotate: flip axis and swap children
	var newAxis Axis
	if oldAxis == AxisRow {
		newAxis = AxisCol
	} else {
		newAxis = AxisRow
	}

	log("rotate: axis " + string(oldAxis) + " -> " + string(newAxis))

	// Create new tree with rotated axis and swapped children
	newRoot := swapChildrenAndSetAxis(root, state.SelectedPath, newAxis)

	// Apply layout
	if err := applyLayout(newRoot, nil); err != nil {
		return err
	}

	log("rotate: done")
	return nil
}
