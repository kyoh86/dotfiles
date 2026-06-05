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
	Type string `json:"type"`
	Pane string `json:"pane"`
	Rect Rect   `json:"rect"`
}

type Split struct {
	Type     string `json:"type"`
	Axis     Axis   `json:"axis"`
	Rect     Rect   `json:"rect"`
	Children []Node `json:"children"`
}

type Node struct {
	LeafNode  *Leaf
	SplitNode *Split
}

func (n *Node) Type() string {
	if n.LeafNode != nil {
		return "leaf"
	}
	return "split"
}

func (n *Node) AsLeaf() *Leaf {
	return n.LeafNode
}

func (n *Node) AsSplit() *Split {
	return n.SplitNode
}

func NewLeaf(pane string, rect Rect) Node {
	return Node{LeafNode: &Leaf{Type: "leaf", Pane: pane, Rect: rect}}
}

func NewSplit(axis Axis, rect Rect, children []Node) Node {
	return Node{SplitNode: &Split{Type: "split", Axis: axis, Rect: rect, Children: children}}
}

type State struct {
	SelectedPath []int    `json:"selectedPath"`
	Preselect    *Axis    `json:"preselect,omitempty"`
	Popups       []string `json:"popups,omitempty"`
}

const (
	SelectBG = "#2a2230"
	FocusBG  = "#33283a"
	Step     = 5
)
