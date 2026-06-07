package main

import (
	"fmt"
	"strconv"
	"strings"
)

func clearStyles() error {
	panesStr, err := tmux("list-panes", "-F", "#{pane_id}")
	if err != nil {
		return err
	}
	panes := strings.SplitSeq(panesStr, "\n")
	for p := range panes {
		if p == "" {
			continue
		}
		if _, err = tmux("set-option", "-upt", p, "window-style"); err != nil {
			log("clearStyles failed for pane " + p + ": " + err.Error())
			return err
		}
	}
	return nil
}

func paneRect(paneID string) (*Rect, error) {
	info, err := tmux("list-panes", "-t", paneID, "-F", "#{pane_left},#{pane_top},#{pane_width},#{pane_height}")
	if err != nil {
		return nil, err
	}
	parts := strings.Split(info, ",")
	if len(parts) != 4 {
		return nil, fmt.Errorf("invalid pane rect: %s", info)
	}
	return &Rect{
		X: mustAtoi(parts[0]),
		Y: mustAtoi(parts[1]),
		W: mustAtoi(parts[2]),
		H: mustAtoi(parts[3]),
	}, nil
}

func nodeRect(node Node) (*Rect, error) {
	if node.IsLeaf() {
		return paneRect(node.AsLeaf().Pane)
	}

	split := node.AsSplit()
	rect1, err := nodeRect(split.Children[0])
	if err != nil {
		return nil, err
	}
	rect2, err := nodeRect(split.Children[1])
	if err != nil {
		return nil, err
	}
	if rect1 == nil {
		return rect2, nil
	}
	if rect2 == nil {
		return rect1, nil
	}

	return &Rect{
		X: min(rect1.X, rect2.X),
		Y: min(rect1.Y, rect2.Y),
		W: max(rect1.X+rect1.W, rect2.X+rect2.W) - min(rect1.X, rect2.X),
		H: max(rect1.Y+rect1.H, rect2.Y+rect2.H) - min(rect1.Y, rect2.Y),
	}, nil
}

func paint(root Node, state *State) error {
	selected := nodeAt(root, state.SelectedPath)
	selectedLeaves := leaves(selected)

	if err := clearStyles(); err != nil {
		return err
	}

	// 選択されたノードが split の場合、children[0] と children[1] の leaves に異なる色を付ける
	// leaf の場合は独自の色を付ける
	if selected.IsLeaf() {
		for _, l := range selectedLeaves {
			if _, err := tmux("set-option", "-pt", l.Pane, "window-style", "bg="+LeafSelectBG); err != nil {
				return err
			}
		}
	} else if selected.IsSplit() {
		split := selected.AsSplit()

		var firstChildLeaves, secondChildLeaves []*Leaf
		if len(split.Children) >= 1 {
			firstChildLeaves = leaves(split.Children[0])
		}
		if len(split.Children) >= 2 {
			secondChildLeaves = leaves(split.Children[1])
		}

		for _, l := range firstChildLeaves {
			if _, err := tmux("set-option", "-pt", l.Pane, "window-style", "bg="+SelectBG); err != nil {
				return err
			}
		}
		for _, l := range secondChildLeaves {
			if _, err := tmux("set-option", "-pt", l.Pane, "window-style", "bg="+SecondChildBG); err != nil {
				return err
			}
		}
	}

	// Show preselect preview
	if state.Preselect != nil {
		selectedRect, err := nodeRect(selected)
		if err == nil && selectedRect != nil {
			if *state.Preselect == AxisRow {
				centerX := selectedRect.X + selectedRect.W/2
				for _, l := range selectedLeaves {
					rect, err := paneRect(l.Pane)
					if err != nil {
						continue
					}
					if rect != nil && rect.X+rect.W/2 > centerX {
						tmuxIgnoreError("set-option", "-pt", l.Pane, "window-style", "bg=#3a2a30")
					}
				}
			} else if *state.Preselect == AxisCol {
				centerY := selectedRect.Y + selectedRect.H/2
				for _, l := range selectedLeaves {
					rect, err := paneRect(l.Pane)
					if err != nil {
						continue
					}
					if rect != nil && rect.Y+rect.H/2 > centerY {
						tmuxIgnoreError("set-option", "-pt", l.Pane, "window-style", "bg=#3a2a30")
					}
				}
			}
		}
	}

	msg := fmt.Sprintf("selection: %s  path=[%s]", compact(selected), strings.Join(intsToStrings(state.SelectedPath), ","))
	if state.Preselect != nil {
		splitDesc := "vertical (right)"
		if *state.Preselect == AxisCol {
			splitDesc = "horizontal (below)"
		}
		axisName := "v"
		if *state.Preselect == AxisCol {
			axisName = "s"
		}
		msg += fmt.Sprintf("  preselect=%s  Enter to split %s", axisName, splitDesc)
	}
	_, err := tmux("display-message", msg)
	return err
}

func swapPane(a, b string) error {
	if a == b {
		return nil
	}
	_, err := tmux("swap-pane", "-s", a, "-t", b)
	return err
}

func growChild(root Node, state *State, child int) error {
	n := nodeAt(root, state.SelectedPath)
	if n.IsLeaf() {
		return nil
	}

	split := n.AsSplit()
	target := firstLeaf(split.Children[child]).Pane

	var direction string
	if split.Axis == AxisRow {
		if child == 0 {
			direction = "-R"
		} else {
			direction = "-L"
		}
	} else {
		if child == 0 {
			direction = "-D"
		} else {
			direction = "-U"
		}
	}

	_, err := tmux("resize-pane", "-t", target, direction, strconv.Itoa(Step))
	return err
}

func splitSelected(root Node, state *State) error {
	if state.Preselect == nil {
		tmuxIgnoreError("display-message", "split ignored: press v or s first")
		return nil
	}

	selected := nodeAt(root, state.SelectedPath)
	target := firstLeaf(selected).Pane

	var flag string
	if *state.Preselect == AxisRow {
		flag = "-h"
	} else {
		flag = "-v"
	}

	if _, err := tmux("split-window", flag, "-t", target, "-P", "-F", "#{pane_id}", "-c", "#{pane_current_path}", "-b"); err != nil {
		return err
	}

	newRoot, err := readTree()
	if err != nil {
		return err
	}

	state.Preselect = nil
	pane, err := currentPane()
	if err != nil {
		return err
	}
	state.SelectedPath = pathOfPane(newRoot, pane)
	if err := saveState(state); err != nil {
		return err
	}
	return paint(newRoot, state)
}
