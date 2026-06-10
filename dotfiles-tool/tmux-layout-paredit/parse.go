package main

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
)

func parseRectParts(w, h, x, y string) Rect {
	return Rect{
		W: mustAtoi(w),
		H: mustAtoi(h),
		X: mustAtoi(x),
		Y: mustAtoi(y),
	}
}

func mustAtoi(s string) int {
	i, err := strconv.Atoi(s)
	if err != nil {
		panic(err)
	}
	return i
}

func safeSubstring(s string, start, length int) string {
	if start > len(s) {
		return s
	}
	end := min(start+length, len(s))
	return s[start:end]
}

func isHex(s string) bool {
	for _, c := range s {
		if (c < '0' || c > '9') && (c < 'a' || c > 'f') && (c < 'A' || c > 'F') {
			return false
		}
	}
	return true
}

func getRect(n Node) Rect {
	if n.IsLeaf() {
		return n.AsLeaf().Rect
	}
	return n.AsSplit().Rect
}

func parseLayout(input string) (Node, error) {
	var i int

	var parseChildren func(end byte) ([]Node, error)
	var parseNode func() (Node, error)

	parseChildren = func(end byte) ([]Node, error) {
		var out []Node
		for i < len(input) && input[i] != end {
			node, err := parseNode()
			if err != nil {
				return nil, err
			}
			out = append(out, node)
			if i < len(input) && input[i] == ',' {
				i++
			}
		}
		if i >= len(input) || input[i] != end {
			return nil, fmt.Errorf("missing %c", end)
		}
		i++
		return out, nil
	}

	parseNode = func() (Node, error) {
		re := regexp.MustCompile(`^([0-9]+)x([0-9]+),([0-9]+),([0-9]+)(?:,([0-9]+))?`)
		rest := input[i:]
		m := re.FindStringSubmatch(rest)
		if m == nil {
			return Node{}, fmt.Errorf("invalid layout node at %d: %s", i, safeSubstring(rest, 0, 40))
		}

		rect := parseRectParts(m[1], m[2], m[3], m[4])
		var paneID *string
		if m[5] != "" {
			pid := "%" + m[5]
			paneID = &pid
		}
		i += len(m[0])

		if i < len(input) && input[i] == '{' {
			i++
			children, err := parseChildren('}')
			if err != nil {
				return Node{}, err
			}
			return NewSplit(AxisRow, rect, children), nil
		}
		if i < len(input) && input[i] == '[' {
			i++
			children, err := parseChildren(']')
			if err != nil {
				return Node{}, err
			}
			return NewSplit(AxisCol, rect, children), nil
		}

		if paneID == nil {
			return Node{}, fmt.Errorf("pane id not found at %d: %s", i, safeSubstring(rest, 0, 40))
		}
		return NewLeaf(*paneID, rect), nil
	}

	firstComma := strings.Index(input, ",")
	if firstComma >= 0 && isHex(input[:firstComma]) {
		i = firstComma + 1
	}

	return parseNode()
}

func normalizeToBinary(node Node) Node {
	if node.IsLeaf() {
		return node
	}

	split := node.AsSplit()
	normalizedChildren := make([]Node, len(split.Children))
	for i, c := range split.Children {
		normalizedChildren[i] = normalizeToBinary(c)
	}

	if len(normalizedChildren) == 0 {
		return node
	}
	if len(normalizedChildren) == 1 {
		return normalizedChildren[0]
	}
	if len(normalizedChildren) == 2 {
		return NewSplit(split.Axis, split.Rect, normalizedChildren)
	}

	result := normalizedChildren[0]
	for i := 1; i < len(normalizedChildren); i++ {
		leftChild := result
		rightChild := normalizedChildren[i]

		var intermediateRect Rect
		if split.Axis == AxisRow {
			intermediateRect = Rect{
				X:      getRect(leftChild).X,
				Y:      getRect(leftChild).Y,
				W:      getRect(leftChild).W + 1 + getRect(rightChild).W,
				H:      max(getRect(leftChild).H, getRect(rightChild).H),
			}
		} else {
			intermediateRect = Rect{
				X:      getRect(leftChild).X,
				Y:      getRect(leftChild).Y,
				W:      max(getRect(leftChild).W, getRect(rightChild).W),
				H:      getRect(leftChild).H + 1 + getRect(rightChild).H,
			}
		}

		if split.Axis == AxisRow {
			newX := getRect(leftChild).X + getRect(leftChild).W + 1
			rightChild = setNodePositionRecursive(rightChild, newX, getRect(rightChild).Y)
		} else {
			newY := getRect(leftChild).Y + getRect(leftChild).H + 1
			rightChild = setNodePositionRecursive(rightChild, getRect(rightChild).X, newY)
		}

		result = NewSplit(split.Axis, intermediateRect, []Node{leftChild, rightChild})
	}
	return result
}

func reconstructLayout(node Node, paneIDOverride map[string]string) string {
	if node.IsLeaf() {
		leaf := node.AsLeaf()
		coordKey := fmt.Sprintf("%d,%d,%d,%d", leaf.Rect.X, leaf.Rect.Y, leaf.Rect.W, leaf.Rect.H)
		var paneID string
		if override, ok := paneIDOverride[coordKey]; ok {
			paneID = override
		} else {
			paneID = leaf.Pane[1:]
		}
		return fmt.Sprintf("%dx%d,%d,%d,%s", leaf.Rect.W, leaf.Rect.H, leaf.Rect.X, leaf.Rect.Y, paneID)
	}

	split := node.AsSplit()
	childrenStrs := make([]string, len(split.Children))
	for i, c := range split.Children {
		childrenStrs[i] = reconstructLayout(c, paneIDOverride)
	}
	childrenStr := strings.Join(childrenStrs, ",")

	var bracket, closing string
	if split.Axis == AxisRow {
		bracket, closing = "{", "}"
	} else {
		bracket, closing = "[", "]"
	}

	var w, h int
	if len(split.Children) > 0 {
		if split.Axis == AxisRow {
			w = 0
			for _, c := range split.Children {
				w += getRect(c).W + 1
			}
			w -= 1
			h = 0
			for _, c := range split.Children {
				ch := getRect(c).H
				if ch > h {
					h = ch
				}
			}
		} else {
			w = split.Rect.W
			h = 0
			for _, c := range split.Children {
				h += getRect(c).H + 1
			}
			h -= 1
		}
	} else {
		w = split.Rect.W
		h = split.Rect.H
	}

	return fmt.Sprintf("%dx%d,%d,%d%s%s%s", w, h, split.Rect.X, split.Rect.Y, bracket, childrenStr, closing)
}

func reconstructLayoutNormalized(node Node, paneIDOverride map[string]string, windowRect Rect) string {
	// Normalize sizes first
	normalizedNode := normalizeSizes(node, windowRect.W, windowRect.H)
	// Set positions
	positionedNode := setNodePositionRecursive(normalizedNode, 0, 0)
	// Reconstruct layout
	return reconstructLayout(positionedNode, paneIDOverride)
}

func calculateChecksum(layout string) string {
	csum := 0
	for i := 0; i < len(layout); i++ {
		char := int(layout[i])
		csum = (csum >> 1) + ((csum & 1) << 15)
		csum += char
		if csum >= 1<<16 {
			csum -= 1 << 16
		}
	}
	return fmt.Sprintf("%04x", csum)
}

func applyLayout(root Node, paneIDOverride map[string]string) error {
	originalLayout, err := tmux("display-message", "-p", "#{window_layout}")
	if err != nil {
		return err
	}
	log("original layout: " + originalLayout)

	windowSize, err := tmux("display-message", "-p", "#{window_width}x#{window_height},0,0")
	if err != nil {
		return err
	}
	var windowRect Rect
	parts := strings.Split(strings.TrimPrefix(windowSize, "%0"), ",")
	if len(parts) >= 2 {
		sizeParts := strings.Split(parts[0], "x")
		if len(sizeParts) == 2 {
			windowRect.W = mustAtoi(sizeParts[0])
			windowRect.H = mustAtoi(sizeParts[1])
		}
	}
	log("window size: " + strconv.Itoa(windowRect.W) + "x" + strconv.Itoa(windowRect.H))

	layout := reconstructLayoutNormalized(root, paneIDOverride, windowRect)
	log("generated layout: " + layout)

	checksum := calculateChecksum(layout)
	log("checksum: " + checksum)

	layoutWithChecksum := checksum + "," + layout
	log("applying layout: " + layoutWithChecksum)
	if _, err = tmux("select-layout", layoutWithChecksum); err != nil {
		log("layout apply failed: " + err.Error())
		return err
	}
	log("layout applied successfully")
	return nil
}
