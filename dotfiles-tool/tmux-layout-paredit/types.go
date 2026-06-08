package main

type Axis string

const (
	AxisRow Axis = "row"
	AxisCol Axis = "col"
)

type Rect struct {
	X int `json:"x"`
	Y int `json:"y"`
	W int `json:"w"`
	H int `json:"h"`
}

type Leaf struct {
	Pane string `json:"pane"`
	Rect Rect   `json:"rect"`
}

type Split struct {
	Axis     Axis   `json:"axis"`
	Rect     Rect   `json:"rect"`
	Children []Node `json:"children"`
}

type Node struct {
	LeafNode  *Leaf
	SplitNode *Split
}

func (n *Node) IsLeaf() bool {
	return n.LeafNode != nil
}

func (n *Node) AsLeaf() *Leaf {
	return n.LeafNode
}

func (n *Node) IsSplit() bool {
	return n.SplitNode != nil
}

func (n *Node) AsSplit() *Split {
	return n.SplitNode
}

func NewLeaf(pane string, rect Rect) Node {
	return Node{LeafNode: &Leaf{Pane: pane, Rect: rect}}
}

func NewSplit(axis Axis, rect Rect, children []Node) Node {
	return Node{SplitNode: &Split{Axis: axis, Rect: rect, Children: children}}
}

type State struct {
	SelectedPath []int `json:"selectedPath"`
}

const (
	SelectBG      = "#616179" // 1番目の子の色 (#c2c2f2 を黒背景に50%合成)
	SecondChildBG = "#6d6d7c" // 2番目の子の色 (#dadaf7 を黒背景に50%合成)
	Step          = 5
)
