package main

import (
	"strconv"
)

func nodeAt(root Node, path []int) Node {
	n := root
	for _, p := range path {
		if n.IsLeaf() {
			return n
		}
		split := n.AsSplit()
		if p >= len(split.Children) {
			return n
		}
		n = split.Children[p]
	}
	return n
}

func parentPath(path []int) []int {
	if len(path) == 0 {
		return path
	}
	return path[:len(path)-1]
}

func siblingPath(path []int) []int {
	if len(path) == 0 {
		return path
	}
	out := make([]int, len(path))
	copy(out, path)
	out[len(out)-1] = 1 - out[len(out)-1]
	return out
}

func leaves(node Node) []*Leaf {
	if node.IsLeaf() {
		return []*Leaf{node.AsLeaf()}
	}
	split := node.AsSplit()
	left, right := leaves(split.Children[0]), leaves(split.Children[1])
	result := make([]*Leaf, 0, len(left)+len(right))
	result = append(result, left...)
	result = append(result, right...)
	return result
}

type NodePath struct {
	Node Node
	Path []int
}

func allNodes(node Node, path []int) []NodePath {
	out := []NodePath{{node, path}}
	if node.IsSplit() {
		split := node.AsSplit()
		leftPath := append([]int{}, path...)
		leftPath = append(leftPath, 0)
		rightPath := append([]int{}, path...)
		rightPath = append(rightPath, 1)
		out = append(out, allNodes(split.Children[0], leftPath)...)
		out = append(out, allNodes(split.Children[1], rightPath)...)
	}
	return out
}

func firstLeaf(node Node) *Leaf {
	return leaves(node)[0]
}

func compact(node Node) string {
	if node.IsLeaf() {
		return node.AsLeaf().Pane
	}
	split := node.AsSplit()
	op := "|"
	if split.Axis == AxisCol {
		op = "/"
	}
	return "(" + compact(split.Children[0]) + op + compact(split.Children[1]) + ")"
}

func intsToStrings(ints []int) []string {
	s := make([]string, len(ints))
	for i, v := range ints {
		s[i] = strconv.Itoa(v)
	}
	return s
}

func pathOfPane(root Node, pane string) []int {
	for _, np := range allNodes(root, nil) {
		if np.Node.IsLeaf() && np.Node.AsLeaf().Pane == pane {
			return np.Path
		}
	}
	return []int{}
}
