package main

import (
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
)

// GitStatus represents git repository status
type GitStatus struct {
	HasGit    bool
	Branch    string
	Remote    string
	Ahead     int
	Behind    int
	Unmerged  int
	Untracked int
	Staged    int
	Unstaged  int
	Dirty     bool
}

func main() {
	path := "."
	if len(os.Args) > 1 {
		path = os.Args[1]
	}

	status, err := getGitStatus(path)
	if err != nil {
		// Silently fail for non-git directories
		os.Exit(0)
	}

	if !status.HasGit {
		os.Exit(0)
	}

	printStatus(status)
}

func getGitStatus(path string) (GitStatus, error) {
	cmd := exec.Command("git", "--no-optional-locks", "status", "--porcelain", "--branch", "--ahead-behind", "--untracked-files", "--renames")
	cmd.Dir = path

	output, err := cmd.Output()
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			stderr := string(exitErr.Stderr)
			if strings.HasPrefix(stderr, "fatal: not a git repository") ||
				strings.HasPrefix(stderr, "fatal: this operation must be run in a work tree") {
				return GitStatus{HasGit: false}, nil
			}
		}
		return GitStatus{HasGit: false}, err
	}

	status := GitStatus{
		HasGit: false,
		Ahead:  0,
		Behind: 0,
	}

	lines := strings.SplitSeq(string(output), "\n")
	for line := range lines {
		if line == "" {
			continue
		}

		if strings.HasPrefix(line, "##") {
			parseBranchLine(line, &status)
		} else if len(line) >= 2 {
			parseFileStatus(line, &status)
		}
	}

	return status, nil
}

func parseBranchLine(line string, status *GitStatus) {
	// Format: ## branch...origin/branch [ahead 3, behind 2]
	//        ## branch
	//        ## branch...origin/branch [behind 1]

	trimmed := strings.TrimPrefix(line, "## ")
	trimmed = strings.TrimSpace(trimmed)

	// Split by "..." to get branch and remote
	parts := strings.SplitN(trimmed, "...", 2)
	if len(parts) == 0 {
		return
	}

	status.Branch = parts[0]
	status.HasGit = status.Branch != ""

	if len(parts) == 1 {
		// No remote info
		return
	}

	remoteAndStats := parts[1]
	// Split by "[" to separate remote and stats
	statsParts := strings.SplitN(remoteAndStats, "[", 2)
	if len(statsParts) >= 1 {
		status.Remote = strings.TrimSpace(statsParts[0])
	}

	if len(statsParts) == 2 {
		// Parse stats like "ahead 3, behind 2]"
		stats := strings.TrimSuffix(statsParts[1], "]")
		statItems := strings.SplitSeq(stats, ",")
		for item := range statItems {
			item = strings.TrimSpace(item)
			if after, ok := strings.CutPrefix(item, "ahead "); ok {
				if n, err := strconv.Atoi(after); err == nil {
					status.Ahead = n
					status.Dirty = true
				}
			} else if after0, ok0 := strings.CutPrefix(item, "behind "); ok0 {
				if n, err := strconv.Atoi(after0); err == nil {
					status.Behind = n
					status.Dirty = true
				}
			}
		}
	}
}

func parseFileStatus(line string, status *GitStatus) {
	if len(line) < 2 {
		return
	}

	staged := string(line[0])
	unstaged := string(line[1])
	changed := string(line[0]) + string(line[1])

	if changed == "??" {
		status.Untracked++
		status.Dirty = true
		return
	}

	if staged == "U" || unstaged == "U" || changed == "AA" || changed == "DD" {
		status.Unmerged++
		status.Dirty = true
		return
	}

	if staged != " " && staged != "?" {
		status.Staged++
		status.Dirty = true
	}

	if unstaged != " " && unstaged != "?" {
		status.Unstaged++
		status.Dirty = true
	}
}

func printStatus(status GitStatus) {
	{
		var parts []string

		// Branch
		if status.Branch != "" {
			parts = append(parts, "\uF418 "+status.Branch)
		}

		// Remote
		if status.Remote != "" {
			parts = append(parts, "\uF427 "+status.Remote)
		} else {
			parts = append(parts, "\U000F0674 ")
		}

		if len(parts) > 0 {
			fmt.Printf("#[fg=green,bg=brightgreen,bold]\uE0BA#[default]#[fg=brightwhite,bg=green,bold] %s #[default]", strings.Join(parts, " "))
		}
	}

	// Stats
	var parts []string
	parts = append(parts, formatStat("\uEAA1 ", status.Ahead))         // x
	parts = append(parts, formatStat("\uEA9A ", status.Behind))        // x
	parts = append(parts, formatStat("\U000F06C4 ", status.Unmerged))  // 󰛄 x
	parts = append(parts, formatStat("\U000F012C ", status.Staged))    // 󰄬 x
	parts = append(parts, formatStat("\U000F0415 ", status.Unstaged))  // 󰐕 x
	parts = append(parts, formatStat("\U000F0205 ", status.Untracked)) // 󰈅 x

	// Filter empty parts
	var result []string
	for _, p := range parts {
		if p != "" {
			result = append(result, p)
		}
	}

	if len(result) > 0 {
		output := strings.Join(result, " ")
		if status.Dirty {
			// Apply style only when dirty
			output = "#[fg=yellow,bg=green,bold]\uE0BA#[default]#[fg=black,bg=yellow,bold] " + output + " #[default]"
		}
		fmt.Print(output)
	}
}

func formatStat(prefix string, value int) string {
	if value == 0 {
		return ""
	}
	return prefix + strconv.Itoa(value)
}
