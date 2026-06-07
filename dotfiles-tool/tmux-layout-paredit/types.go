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
	SelectedPath []int    `json:"selectedPath"`
	Preselect    *Axis    `json:"preselect,omitempty"`
	Popups       []string `json:"popups,omitempty"`
}

const (
	SelectBG      = "#c2c2f2"  // 1番目の子の色 (rgba(194, 194, 242))
	SecondChildBG = "#dadaf7"  // 2番目の子の色 (ベース色 + 半透明白色40%)
	LeafSelectBG  = "#f2c2c2"  // leaf がフォーカスされた場合 (rgba(242, 194, 194))
	Step          = 5
)
