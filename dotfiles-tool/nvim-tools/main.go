package main

import (
	"fmt"
	"os"
)

func run(args []string) error {
	if len(args) == 2 && args[0] == "title" {
		title, err := fetchTitle(args[1])
		if err != nil {
			return err
		}
		fmt.Fprintln(os.Stdout, title)
		return nil
	}
	if len(args) >= 3 && args[0] == "snippets" {
		switch args[1] {
		case "compile":
			if len(args) >= 4 {
				return compileSnippets(args[2], args[3:])
			}
		case "decompile":
			if len(args) == 3 {
				return decompileSnippets(args[2], os.Stdin)
			}
		}
	}
	return fmt.Errorf("usage: nvim-tools title URL | snippets compile FILE DIR... | snippets decompile FILE")
}

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
