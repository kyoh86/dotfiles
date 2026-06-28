package main

import (
	"testing"
)

func TestShortenPath(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		{"", "."},
		{".", "."},
		{"single", "single"},

		{"~", "~"},
		{"~/single", "~/single"},
		{"~/a/b", "~/a/b"},
		{"~/a/b/c", "~/a/b/c"},

		{"~/Long/name", "~/Long/name"},
		{"~/Long/name/path", "~/L/n/path"},
		{"~/Long/.name/path", "~/L/.n/path"},

		{"/", "/"},
		{"/single", "/single"},
		{"/a/b", "/a/b"},
		{"/a/b/c", "/a/b/c"},
		{"/a/b/c/d", "/a/b/c/d"},

		{"/Long/name/to", "/Long/name/to"},
		{"/Long/name/to/path", "/L/n/t/path"},
		{"/Long/.name/to/path", "/L/.n/t/path"},

		{"~/Long/name/to/path/.wt/main", "~/L/n/t/path@main"},
		{"~/Long/name/to/path/.wt/other/structure", "~/L/n/t/p/.w/o/structure"},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			got := shortenPath(tt.input)
			if got != tt.want {
				t.Errorf("shortenPath(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}
