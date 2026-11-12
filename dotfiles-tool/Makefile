dest/git-status-line: git-status-line/main.go
	go build -buildvcs=false -o dest/git-status-line ./git-status-line

dest/tmux-layout-paredit: tmux-layout-paredit/*.go
	go build -buildvcs=false -o dest/tmux-layout-paredit ./tmux-layout-paredit

dest/tmux-smart-focus: tmux-smart-focus/*.go
	cd tmux-smart-focus && go build -buildvcs=false -o ../dest/tmux-smart-focus .

dest/path-shorten: path-shorten/main.go
	go build -buildvcs=false -o dest/path-shorten ./path-shorten

dest/pick-services: pick-services/*.go go.mod go.sum
	go build -buildvcs=false -o dest/pick-services ./pick-services

.PHONY: install
install: \
 dest/git-status-line \
 dest/tmux-layout-paredit \
 dest/tmux-smart-focus \
 dest/path-shorten \
 dest/pick-services
