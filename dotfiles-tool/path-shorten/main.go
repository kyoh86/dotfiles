package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	path := "."
	if len(os.Args) > 1 {
		path = os.Args[1]
	}

	absPath, err := filepath.Abs(path)
	if err != nil {
		// Fallback to input path if abs fails
		absPath = path
	}

	homeDir, err := os.UserHomeDir()
	if err == nil && strings.HasPrefix(absPath, homeDir) {
		absPath = "~" + strings.TrimPrefix(absPath, homeDir)
	}

	shortened := shortenPath(absPath)
	fmt.Print(shortened)
}

func shortenPath(path string) string {
	if path == "" || path == "." {
		return "."
	}

	// Split path into segments
	segments := strings.Split(path, string(filepath.Separator))

	// Check if this is an absolute path (starts with /)
	isAbsolute := segments[0] == ""

	// Filter out empty segments (but remember if it was absolute)
	var filtered []string
	for _, s := range segments {
		if s != "" {
			filtered = append(filtered, s)
		}
	}

	// Check for .worktree/(branch) pattern at the end
	var worktreeBranch string
	for i, s := range filtered {
		if s == ".worktree" && i+1 < len(filtered) {
			// Check if this is at the end (i+2 == len(filtered))
			if i+2 == len(filtered) {
				worktreeBranch = filtered[i+1]
				// Remove .worktree and branch from filtered
				filtered = append(filtered[:i], filtered[i+2:]...)
				break
			}
			// Not at the end, don't remove .worktree
			break
		}
	}

	// 3 segments or less: keep as is (but add worktree branch if present)
	if len(filtered) <= 3 {
		result := path
		if worktreeBranch != "" {
			// Remove .worktree/(branch) from original path and add @(branch)
			result = strings.Replace(result, "/.worktree/"+worktreeBranch, "", 1)
			result = strings.Replace(result, "\\.worktree\\"+worktreeBranch, "", 1)
			result = result + "@" + worktreeBranch
		}
		return result
	}

	// 4+ segments: shorten middle segments (including first), keep last full
	result := []string{}

	// Shorten all segments except the last
	for i := 0; i < len(filtered)-1; i++ {
		seg := filtered[i]
		if len(seg) > 1 && seg[0] == '.' {
			// For dot files/directories, keep first 2 characters
			result = append(result, seg[:2])
		} else {
			// Otherwise keep first character
			result = append(result, string(seg[0]))
		}
	}

	// Keep last segment full
	result = append(result, filtered[len(filtered)-1])

	output := strings.Join(result, string(filepath.Separator))
	if isAbsolute {
		output = string(filepath.Separator) + output
	}

	if worktreeBranch != "" {
		output = output + "@" + worktreeBranch
	}

	return output
}
