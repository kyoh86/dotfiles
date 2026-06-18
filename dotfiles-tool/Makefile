bin/git-status-line: git-status-line/main.go
	go build -buildvcs=false -o bin/git-status-line ./git-status-line

bin/tmux-layout-paredit: tmux-layout-paredit/*.go
	go build -buildvcs=false -o bin/tmux-layout-paredit ./tmux-layout-paredit

bin/tmux-smart-focus: tmux-smart-focus/*.go
	cd tmux-smart-focus && go build -buildvcs=false -o ../bin/tmux-smart-focus .

bin/path-shorten: path-shorten/main.go
	go build -buildvcs=false -o bin/path-shorten ./path-shorten

.PHONY: install
install: \
 bin/git-status-line \
 bin/tmux-layout-paredit \
 bin/tmux-smart-focus \
 bin/path-shorten
