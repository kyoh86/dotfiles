package main

import (
	"fmt"
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
			if _, err := tmux("set-option", "-pt", l.Pane, "window-style", "bg="+SelectBG); err != nil {
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

	msg := fmt.Sprintf("selection: %s  path=[%s]", compact(selected), strings.Join(intsToStrings(state.SelectedPath), ","))
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
