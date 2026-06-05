package main

import (
	"reflect"
	"testing"
)

func TestParseLayout(t *testing.T) {
	tests := []struct {
		name    string
		input   string
		wantErr bool
		check   func(Node) bool
	}{
		{
			name:    "single pane",
			input:   "145x71,0,0,0",
			wantErr: false,
			check: func(n Node) bool {
				return n.Type() == "leaf" && n.AsLeaf().Pane == "%0"
			},
		},
		{
			name:    "single pane with checksum",
			input:   "b7fd,145x71,0,0,0",
			wantErr: false,
			check: func(n Node) bool {
				return n.Type() == "leaf" && n.AsLeaf().Pane == "%0"
			},
		},
		{
			name:    "row split with two panes",
			input:   "145x71,0,0{73x71,0,0,0,72x71,74,0,1}",
			wantErr: false,
			check: func(n Node) bool {
				if n.Type() != "split" || n.AsSplit().Axis != AxisRow {
					return false
				}
				return len(n.AsSplit().Children) == 2
			},
		},
		{
			name:    "col split with two panes",
			input:   "145x71,0,0[73x71,0,0,0,72x71,0,73,1]",
			wantErr: false,
			check: func(n Node) bool {
				if n.Type() != "split" || n.AsSplit().Axis != AxisCol {
					return false
				}
				return len(n.AsSplit().Children) == 2
			},
		},
		{
			name:    "invalid layout",
			input:   "invalid",
			wantErr: true,
			check:   nil,
		},
		{
			name:    "empty layout",
			input:   "",
			wantErr: true,
			check:   nil,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := parseLayout(tt.input)
			if (err != nil) != tt.wantErr {
				t.Errorf("parseLayout() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !tt.wantErr && tt.check != nil && !tt.check(got) {
				t.Errorf("parseLayout() check failed")
			}
		})
	}
}

func TestNormalizeToBinary(t *testing.T) {
	tests := []struct {
		name  string
		input Node
		check func(Node) bool
	}{
		{
			name:  "leaf node stays leaf",
			input: NewLeaf("%0", Rect{X: 0, Y: 0, W: 100, H: 50}),
			check: func(n Node) bool {
				return n.Type() == "leaf"
			},
		},
		{
			name: "single child becomes child",
			input: NewSplit(AxisRow, Rect{X: 0, Y: 0, W: 100, H: 50}, []Node{
				NewLeaf("%0", Rect{X: 0, Y: 0, W: 100, H: 50}),
			}),
			check: func(n Node) bool {
				return n.Type() == "leaf" && n.AsLeaf().Pane == "%0"
			},
		},
		{
			name: "two children stays binary",
			input: NewSplit(AxisRow, Rect{X: 0, Y: 0, W: 100, H: 50}, []Node{
				NewLeaf("%0", Rect{X: 0, Y: 0, W: 50, H: 50}),
				NewLeaf("%1", Rect{X: 51, Y: 0, W: 49, H: 50}),
			}),
			check: func(n Node) bool {
				if n.Type() != "split" || len(n.AsSplit().Children) != 2 {
					return false
				}
				return true
			},
		},
		{
			name: "three children becomes binary",
			input: NewSplit(AxisRow, Rect{X: 0, Y: 0, W: 100, H: 50}, []Node{
				NewLeaf("%0", Rect{X: 0, Y: 0, W: 33, H: 50}),
				NewLeaf("%1", Rect{X: 34, Y: 0, W: 33, H: 50}),
				NewLeaf("%2", Rect{X: 68, Y: 0, W: 32, H: 50}),
			}),
			check: func(n Node) bool {
				if n.Type() != "split" {
					return false
				}
				split := n.AsSplit()
				if len(split.Children) != 2 {
					return false
				}
				// Should be [[%0, %1], %2]
				return true
			},
		},
		{
			name: "four children becomes left-associative binary",
			input: NewSplit(AxisRow, Rect{X: 0, Y: 0, W: 100, H: 50}, []Node{
				NewLeaf("%0", Rect{X: 0, Y: 0, W: 25, H: 50}),
				NewLeaf("%1", Rect{X: 26, Y: 0, W: 25, H: 50}),
				NewLeaf("%2", Rect{X: 52, Y: 0, W: 25, H: 50}),
				NewLeaf("%3", Rect{X: 78, Y: 0, W: 22, H: 50}),
			}),
			check: func(n Node) bool {
				if n.Type() != "split" {
					return false
				}
				return len(n.AsSplit().Children) == 2
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := normalizeToBinary(tt.input)
			if !tt.check(got) {
				t.Errorf("normalizeToBinary() check failed")
			}
		})
	}
}

func TestGetRect(t *testing.T) {
	tests := []struct {
		name string
		node Node
		want Rect
	}{
		{
			name: "leaf node",
			node: NewLeaf("%0", Rect{X: 10, Y: 20, W: 30, H: 40}),
			want: Rect{X: 10, Y: 20, W: 30, H: 40},
		},
		{
			name: "split node",
			node: NewSplit(AxisRow, Rect{X: 5, Y: 15, W: 25, H: 35}, []Node{
				NewLeaf("%0", Rect{X: 0, Y: 0, W: 1, H: 1}),
				NewLeaf("%1", Rect{X: 0, Y: 0, W: 1, H: 1}),
			}),
			want: Rect{X: 5, Y: 15, W: 25, H: 35},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := getRect(tt.node)
			if got != tt.want {
				t.Errorf("getRect() = %+v, want %+v", got, tt.want)
			}
		})
	}
}

func TestRecalculateRects(t *testing.T) {
	// Build a simple binary tree
	leaf1 := NewLeaf("%0", Rect{X: 0, Y: 0, W: 50, H: 50})
	leaf2 := NewLeaf("%1", Rect{X: 51, Y: 0, W: 49, H: 50})
	split := NewSplit(AxisRow, Rect{X: 0, Y: 0, W: 100, H: 50}, []Node{leaf1, leaf2})

	got := recalculateRects(split, nil)
	if got.Type() != "split" {
		t.Fatalf("expected split, got %s", got.Type())
	}

	splitNode := got.AsSplit()
	if splitNode.Rect.W != 100 || splitNode.Rect.H != 50 {
		t.Errorf("rect = %+v, want W=100 H=50", splitNode.Rect)
	}
}

func TestPathOperations(t *testing.T) {
	// Build a tree: [[%0, %1], %2]
	leaf0 := NewLeaf("%0", Rect{X: 0, Y: 0, W: 1, H: 1})
	leaf1 := NewLeaf("%1", Rect{X: 0, Y: 0, W: 1, H: 1})
	leaf2 := NewLeaf("%2", Rect{X: 0, Y: 0, W: 1, H: 1})
	leftSplit := NewSplit(AxisRow, Rect{X: 0, Y: 0, W: 1, H: 1}, []Node{leaf0, leaf1})
	root := NewSplit(AxisRow, Rect{X: 0, Y: 0, W: 1, H: 1}, []Node{leftSplit, leaf2})

	t.Run("nodeAt", func(t *testing.T) {
		tests := []struct {
			path []int
			want string
		}{
			{[]int{}, "split"},
			{[]int{0}, "split"},
			{[]int{0, 0}, "leaf"},
			{[]int{0, 1}, "leaf"},
			{[]int{1}, "leaf"},
		}
		for _, tt := range tests {
			got := nodeAt(root, tt.path)
			if tt.want == "leaf" && got.Type() != "leaf" {
				t.Errorf("nodeAt(%v) = %s, want leaf", tt.path, got.Type())
			}
			if tt.want == "split" && got.Type() != "split" {
				t.Errorf("nodeAt(%v) = %s, want split", tt.path, got.Type())
			}
		}
	})

	t.Run("parentPath", func(t *testing.T) {
		tests := []struct {
			path []int
			want []int
		}{
			{[]int{0, 0}, []int{0}},
			{[]int{0}, []int{}},
			{[]int{}, []int{}},
		}
		for _, tt := range tests {
			got := parentPath(tt.path)
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("parentPath(%v) = %v, want %v", tt.path, got, tt.want)
			}
		}
	})

	t.Run("siblingPath", func(t *testing.T) {
		tests := []struct {
			path []int
			want []int
		}{
			{[]int{0, 0}, []int{0, 1}},
			{[]int{0, 1}, []int{0, 0}},
			{[]int{1}, []int{0}},
		}
		for _, tt := range tests {
			got := siblingPath(tt.path)
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("siblingPath(%v) = %v, want %v", tt.path, got, tt.want)
			}
		}
	})
}

func TestSwapChildren(t *testing.T) {
	leaf1 := NewLeaf("%0", Rect{X: 0, Y: 0, W: 50, H: 50})
	leaf2 := NewLeaf("%1", Rect{X: 51, Y: 0, W: 49, H: 50})
	split := NewSplit(AxisRow, Rect{X: 0, Y: 0, W: 100, H: 50}, []Node{leaf1, leaf2})

	// Swap children at path []
	got := swapChildren(split, []int{})
	if got.Type() != "split" {
		t.Fatalf("expected split, got %s", got.Type())
	}

	splitNode := got.AsSplit()
	if splitNode.Children[0].AsLeaf().Pane != "%1" {
		t.Errorf("expected children[0] to be %%1, got %s", splitNode.Children[0].AsLeaf().Pane)
	}
	if splitNode.Children[1].AsLeaf().Pane != "%0" {
		t.Errorf("expected children[1] to be %%0, got %s", splitNode.Children[1].AsLeaf().Pane)
	}
}

func TestLeaves(t *testing.T) {
	t.Run("single leaf", func(t *testing.T) {
		leaf := NewLeaf("%0", Rect{X: 0, Y: 0, W: 100, H: 50})
		got := leaves(leaf)
		if len(got) != 1 || got[0].Pane != "%0" {
			t.Errorf("expected [%%0], got %v", got)
		}
	})

	t.Run("binary tree", func(t *testing.T) {
		leaf0 := NewLeaf("%0", Rect{X: 0, Y: 0, W: 1, H: 1})
		leaf1 := NewLeaf("%1", Rect{X: 0, Y: 0, W: 1, H: 1})
		leaf2 := NewLeaf("%2", Rect{X: 0, Y: 0, W: 1, H: 1})
		leftSplit := NewSplit(AxisRow, Rect{X: 0, Y: 0, W: 1, H: 1}, []Node{leaf0, leaf1})
		root := NewSplit(AxisRow, Rect{X: 0, Y: 0, W: 1, H: 1}, []Node{leftSplit, leaf2})

		got := leaves(root)
		if len(got) != 3 {
			t.Fatalf("expected 3 leaves, got %d", len(got))
		}
		if got[0].Pane != "%0" || got[1].Pane != "%1" || got[2].Pane != "%2" {
			t.Errorf("expected [%%0, %%1, %%2], got %v", got)
		}
	})

	t.Run("nested col then row", func(t *testing.T) {
		leaf0 := NewLeaf("%0", Rect{X: 0, Y: 0, W: 1, H: 1})
		leaf1 := NewLeaf("%1", Rect{X: 0, Y: 0, W: 1, H: 1})
		leaf2 := NewLeaf("%2", Rect{X: 0, Y: 0, W: 1, H: 1})
		leftSplit := NewSplit(AxisCol, Rect{X: 0, Y: 0, W: 1, H: 1}, []Node{leaf0, leaf1})
		root := NewSplit(AxisRow, Rect{X: 0, Y: 0, W: 1, H: 1}, []Node{leftSplit, leaf2})

		got := leaves(root)
		if len(got) != 3 {
			t.Fatalf("expected 3 leaves, got %d", len(got))
		}
		if got[0].Pane != "%0" || got[1].Pane != "%1" || got[2].Pane != "%2" {
			t.Errorf("expected [%%0, %%1, %%2], got %v", got)
		}
	})
}

func TestAllNodes(t *testing.T) {
	t.Run("single leaf", func(t *testing.T) {
		leaf := NewLeaf("%0", Rect{X: 0, Y: 0, W: 1, H: 1})
		got := allNodes(leaf, []int{})
		if len(got) != 1 {
			t.Fatalf("expected 1 node, got %d", len(got))
		}
		if got[0].Node.Type() != "leaf" {
			t.Errorf("expected leaf, got %s", got[0].Node.Type())
		}
	})

	t.Run("binary tree", func(t *testing.T) {
		leaf0 := NewLeaf("%0", Rect{X: 0, Y: 0, W: 1, H: 1})
		leaf1 := NewLeaf("%1", Rect{X: 0, Y: 0, W: 1, H: 1})
		leaf2 := NewLeaf("%2", Rect{X: 0, Y: 0, W: 1, H: 1})
		leftSplit := NewSplit(AxisRow, Rect{X: 0, Y: 0, W: 1, H: 1}, []Node{leaf0, leaf1})
		root := NewSplit(AxisRow, Rect{X: 0, Y: 0, W: 1, H: 1}, []Node{leftSplit, leaf2})

		got := allNodes(root, []int{})
		// Should have: root([0,1]), leftSplit([0]), %0([0,0]), %1([0,1]), %2([1])
		if len(got) != 5 {
			t.Fatalf("expected 5 nodes, got %d", len(got))
		}
	})
}

func TestFirstLeaf(t *testing.T) {
	t.Run("leaf node", func(t *testing.T) {
		leaf := NewLeaf("%0", Rect{X: 0, Y: 0, W: 1, H: 1})
		got := firstLeaf(leaf)
		if got.Pane != "%0" {
			t.Errorf("expected %%0, got %s", got.Pane)
		}
	})

	t.Run("split node", func(t *testing.T) {
		leaf0 := NewLeaf("%0", Rect{X: 0, Y: 0, W: 1, H: 1})
		leaf1 := NewLeaf("%1", Rect{X: 0, Y: 0, W: 1, H: 1})
		split := NewSplit(AxisRow, Rect{X: 0, Y: 0, W: 1, H: 1}, []Node{leaf0, leaf1})

		got := firstLeaf(split)
		if got.Pane != "%0" {
			t.Errorf("expected %%0, got %s", got.Pane)
		}
	})
}

func TestCompact(t *testing.T) {
	t.Run("leaf", func(t *testing.T) {
		leaf := NewLeaf("%0", Rect{X: 0, Y: 0, W: 1, H: 1})
		got := compact(leaf)
		if got != "%0" {
			t.Errorf("expected %%0, got %s", got)
		}
	})

	t.Run("row split", func(t *testing.T) {
		leaf0 := NewLeaf("%0", Rect{X: 0, Y: 0, W: 1, H: 1})
		leaf1 := NewLeaf("%1", Rect{X: 0, Y: 0, W: 1, H: 1})
		split := NewSplit(AxisRow, Rect{X: 0, Y: 0, W: 1, H: 1}, []Node{leaf0, leaf1})

		got := compact(split)
		if got != "(%0|%1)" {
			t.Errorf("expected (%%0|%%1), got %s", got)
		}
	})

	t.Run("col split", func(t *testing.T) {
		leaf0 := NewLeaf("%0", Rect{X: 0, Y: 0, W: 1, H: 1})
		leaf1 := NewLeaf("%1", Rect{X: 0, Y: 0, W: 1, H: 1})
		split := NewSplit(AxisCol, Rect{X: 0, Y: 0, W: 1, H: 1}, []Node{leaf0, leaf1})

		got := compact(split)
		if got != "(%0/%1)" {
			t.Errorf("expected (%%0/%%1), got %s", got)
		}
	})

	t.Run("nested", func(t *testing.T) {
		leaf0 := NewLeaf("%0", Rect{X: 0, Y: 0, W: 1, H: 1})
		leaf1 := NewLeaf("%1", Rect{X: 0, Y: 0, W: 1, H: 1})
		leaf2 := NewLeaf("%2", Rect{X: 0, Y: 0, W: 1, H: 1})
		leftSplit := NewSplit(AxisRow, Rect{X: 0, Y: 0, W: 1, H: 1}, []Node{leaf0, leaf1})
		root := NewSplit(AxisCol, Rect{X: 0, Y: 0, W: 1, H: 1}, []Node{leftSplit, leaf2})

		got := compact(root)
		if got != "((%0|%1)/%2)" {
			t.Errorf("expected ((%%0|%%1)/%%2), got %s", got)
		}
	})
}

func TestPathOfPane(t *testing.T) {
	leaf0 := NewLeaf("%0", Rect{X: 0, Y: 0, W: 1, H: 1})
	leaf1 := NewLeaf("%1", Rect{X: 0, Y: 0, W: 1, H: 1})
	leaf2 := NewLeaf("%2", Rect{X: 0, Y: 0, W: 1, H: 1})
	leftSplit := NewSplit(AxisRow, Rect{X: 0, Y: 0, W: 1, H: 1}, []Node{leaf0, leaf1})
	root := NewSplit(AxisRow, Rect{X: 0, Y: 0, W: 1, H: 1}, []Node{leftSplit, leaf2})

	tests := []struct {
		pane       string
		wantPath   []int
		wantFound  bool
	}{
		{"%0", []int{0, 0}, true},
		{"%1", []int{0, 1}, true},
		{"%2", []int{1}, true},
		{"%3", []int{}, false},
	}

	for _, tt := range tests {
		t.Run(tt.pane, func(t *testing.T) {
			got := pathOfPane(root, tt.pane)
			if tt.wantFound && len(got) == 0 {
				t.Errorf("expected path %v, got empty", tt.wantPath)
			}
			if !tt.wantFound && len(got) != 0 {
				t.Errorf("expected empty path, got %v", got)
			}
		})
	}
}

func TestIntsToStrings(t *testing.T) {
	tests := []struct {
		input []int
		want  []string
	}{
		{[]int{}, []string{}},
		{[]int{0}, []string{"0"}},
		{[]int{0, 1, 2}, []string{"0", "1", "2"}},
		{[]int{10, 20}, []string{"10", "20"}},
	}

	for _, tt := range tests {
		t.Run("", func(t *testing.T) {
			got := intsToStrings(tt.input)
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("intsToStrings(%v) = %v, want %v", tt.input, got, tt.want)
			}
		})
	}
}

func TestLeafPanes(t *testing.T) {
	t.Run("empty list", func(t *testing.T) {
		got := leafPanes([]*Leaf{})
		if got != "" {
			t.Errorf("expected empty string, got %s", got)
		}
	})

	t.Run("single pane", func(t *testing.T) {
		leaf := &Leaf{Pane: "%0", Rect: Rect{X: 0, Y: 0, W: 1, H: 1}}
		got := leafPanes([]*Leaf{leaf})
		if got != "%0" {
			t.Errorf("expected %%0, got %s", got)
		}
	})

	t.Run("multiple panes", func(t *testing.T) {
		leaf0 := &Leaf{Pane: "%0", Rect: Rect{X: 0, Y: 0, W: 1, H: 1}}
		leaf1 := &Leaf{Pane: "%1", Rect: Rect{X: 0, Y: 0, W: 1, H: 1}}
		leaf2 := &Leaf{Pane: "%2", Rect: Rect{X: 0, Y: 0, W: 1, H: 1}}
		got := leafPanes([]*Leaf{leaf0, leaf1, leaf2})
		if got != "%0, %1, %2" {
			t.Errorf("expected %%0, %%1, %%2, got %s", got)
		}
	})
}

func TestReconstructLayout(t *testing.T) {
	t.Run("single leaf", func(t *testing.T) {
		leaf := NewLeaf("%0", Rect{X: 0, Y: 0, W: 100, H: 50})
		got := reconstructLayout(leaf, nil)
		if got != "100x50,0,0,0" {
			t.Errorf("expected 100x50,0,0,0, got %s", got)
		}
	})

	t.Run("row split with two panes", func(t *testing.T) {
		leaf0 := NewLeaf("%0", Rect{X: 0, Y: 0, W: 50, H: 50})
		leaf1 := NewLeaf("%1", Rect{X: 51, Y: 0, W: 49, H: 50})
		split := NewSplit(AxisRow, Rect{X: 0, Y: 0, W: 100, H: 50}, []Node{leaf0, leaf1})

		got := reconstructLayout(split, nil)
		if got != "100x50,0,0{50x50,0,0,0,49x50,51,0,1}" {
			t.Errorf("got %s", got)
		}
	})

	t.Run("col split with two panes", func(t *testing.T) {
		leaf0 := NewLeaf("%0", Rect{X: 0, Y: 0, W: 100, H: 25})
		leaf1 := NewLeaf("%1", Rect{X: 0, Y: 26, W: 100, H: 25})
		split := NewSplit(AxisCol, Rect{X: 0, Y: 0, W: 100, H: 50}, []Node{leaf0, leaf1})

		got := reconstructLayout(split, nil)
		if got != "100x50,0,0[100x25,0,0,0,100x25,0,26,1]" {
			t.Errorf("got %s", got)
		}
	})

	t.Run("nested layout", func(t *testing.T) {
		leaf0 := NewLeaf("%0", Rect{X: 0, Y: 0, W: 25, H: 25})
		leaf1 := NewLeaf("%1", Rect{X: 26, Y: 0, W: 24, H: 25})
		leaf2 := NewLeaf("%2", Rect{X: 0, Y: 0, W: 49, H: 25})
		leftSplit := NewSplit(AxisRow, Rect{X: 0, Y: 0, W: 49, H: 25}, []Node{leaf0, leaf1})
		root := NewSplit(AxisCol, Rect{X: 0, Y: 0, W: 49, H: 50}, []Node{leftSplit, leaf2})

		got := reconstructLayout(root, nil)
		// Expected: [[%0|%1]/%2]
		expected := "49x50,0,0[49x25,0,0{25x25,0,0,0,24x25,26,0,1},49x25,0,0,2]"
		if got != expected {
			t.Errorf("expected %s, got %s", expected, got)
		}
	})

	t.Run("with pane ID override", func(t *testing.T) {
		leaf := NewLeaf("%0", Rect{X: 10, Y: 20, W: 30, H: 40})
		override := map[string]string{
			"10,20,30,40": "5",
		}
		got := reconstructLayout(leaf, override)
		if got != "30x40,10,20,5" {
			t.Errorf("expected 30x40,10,20,5, got %s", got)
		}
	})
}

func TestCalculateChecksum(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		{"", "0000"},
		{"a", "0061"},
		{"100x50,0,0,0", "ac7d"},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			got := calculateChecksum(tt.input)
			if got != tt.want {
				t.Errorf("calculateChecksum(%s) = %s, want %s", tt.input, got, tt.want)
			}
		})
	}
}
