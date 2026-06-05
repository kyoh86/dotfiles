package main

import (
	"reflect"
	"testing"
)

func TestParseBranchLine(t *testing.T) {
	tests := []struct {
		name   string
		input  string
		want   GitStatus
	}{
		{
			name:  "branch only",
			input: "## main",
			want: GitStatus{
				Branch: "main",
				HasGit: true,
			},
		},
		{
			name:  "branch with remote",
			input: "## main...origin/main",
			want: GitStatus{
				Branch: "main",
				Remote: "origin/main",
				HasGit: true,
			},
		},
		{
			name:  "branch with ahead",
			input: "## main...origin/main [ahead 3]",
			want: GitStatus{
				Branch: "main",
				Remote: "origin/main",
				Ahead:  3,
				Dirty:  true,
				HasGit: true,
			},
		},
		{
			name:  "branch with behind",
			input: "## main...origin/main [behind 2]",
			want: GitStatus{
				Branch: "main",
				Remote: "origin/main",
				Behind: 2,
				Dirty:  true,
				HasGit: true,
			},
		},
		{
			name:  "branch with both",
			input: "## main...origin/main [ahead 3, behind 2]",
			want: GitStatus{
				Branch: "main",
				Remote: "origin/main",
				Ahead:  3,
				Behind: 2,
				Dirty:  true,
				HasGit: true,
			},
		},
		{
			name:  "feature branch no remote",
			input: "## feature-1",
			want: GitStatus{
				Branch: "feature-1",
				HasGit: true,
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := GitStatus{}
			parseBranchLine(tt.input, &got)
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("parseBranchLine() = %+v, want %+v", got, tt.want)
			}
		})
	}
}

func TestParseFileStatus(t *testing.T) {
	tests := []struct {
		name   string
		input  string
		want   GitStatus
	}{
		{
			name:  "untracked",
			input: "?? file.txt",
			want: GitStatus{
				Untracked: 1,
				Dirty:     true,
			},
		},
		{
			name:  "staged only",
			input: "M  file.txt",
			want: GitStatus{
				Staged: 1,
				Dirty: true,
			},
		},
		{
			name:  "unstaged only",
			input: " M file.txt",
			want: GitStatus{
				Unstaged: 1,
				Dirty:    true,
			},
		},
		{
			name:  "both staged and unstaged",
			input: "MM file.txt",
			want: GitStatus{
				Staged:   1,
				Unstaged: 1,
				Dirty:    true,
			},
		},
		{
			name:  "unmerged both",
			input: "UU file.txt",
			want: GitStatus{
				Unmerged: 1,
				Dirty:    true,
			},
		},
		{
			name:  "unmerged staged",
			input: "U  file.txt",
			want: GitStatus{
				Unmerged: 1,
				Dirty:    true,
			},
		},
		{
			name:  "unmerged unstaged",
			input: " U file.txt",
			want: GitStatus{
				Unmerged: 1,
				Dirty:    true,
			},
		},
		{
			name:  "added",
			input: "A  file.txt",
			want: GitStatus{
				Staged: 1,
				Dirty: true,
			},
		},
		{
			name:  "deleted staged",
			input: "D  file.txt",
			want: GitStatus{
				Staged: 1,
				Dirty: true,
			},
		},
		{
			name:  "deleted unstaged",
			input: " D file.txt",
			want: GitStatus{
				Unstaged: 1,
				Dirty:    true,
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := GitStatus{}
			parseFileStatus(tt.input, &got)
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("parseFileStatus(%q) = %+v, want %+v", tt.input, got, tt.want)
			}
		})
	}
}

func TestFormatStat(t *testing.T) {
	tests := []struct {
		prefix  string
		value   int
		want    string
	}{
		{"", 0, ""},
		{"x", 0, ""},
		{"", 5, "5"},
		{"x", 3, "x3"},
	}

	for _, tt := range tests {
		t.Run("", func(t *testing.T) {
			got := formatStat(tt.prefix, tt.value)
			if got != tt.want {
				t.Errorf("formatStat(%q, %d) = %q, want %q", tt.prefix, tt.value, got, tt.want)
			}
		})
	}
}
