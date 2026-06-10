bin/git-status-line: git-status-line/main.go
	go build -o bin/git-status-line ./git-status-line

bin/tmux-layout-paredit: tmux-layout-paredit/*.go
	go build -o bin/tmux-layout-paredit ./tmux-layout-paredit

bin/tmux-smart-focus: tmux-smart-focus/*.go
	go build -o bin/tmux-smart-focus ./tmux-smart-focus

bin/path-shorten: path-shorten/main.go
	go build -o bin/path-shorten ./path-shorten

.PHONY: install
install: \
 bin/git-status-line \
 bin/tmux-layout-paredit \
 bin/tmux-smart-focus \
 bin/path-shorten
