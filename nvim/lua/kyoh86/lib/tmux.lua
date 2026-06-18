local M = {}

function M.focus_nvim_pane()
	if vim.env.TMUX_PANE == nil or vim.env.TMUX_PANE == "" then
		return
	end
	pcall(function()
		vim.system({ "tmux", "select-pane", "-t", vim.env.TMUX_PANE }):wait()
	end)
end

function M.pane_count()
	if not vim.env.TMUX then
		return 0
	end
	local result = vim.system({ "tmux", "list-panes", "-F", "#{pane_id}" }, { text = true }):wait()
	if result.code ~= 0 then
		return 0
	end
	local count = 0
	for line in vim.gsplit(result.stdout, "\n", { plain = true, trimempty = true }) do
		if line ~= "" then
			count = count + 1
		end
	end
	return count
end

function M.focus_edge(direction)
	local commands = {
		h = "l",
		j = "k",
		k = "j",
		l = "h",
	}
	local command = commands[direction]
	if command == nil then
		return false
	end
	while true do
		local before = vim.api.nvim_get_current_win()
		vim.cmd("wincmd " .. command)
		if vim.api.nvim_get_current_win() == before then
			break
		end
	end
	return true
end

---@class kyoh86.lib.tmux.RunOptions
---@field split? "horizontal"|"vertical" A direction to split new pane. Default: "vertical"
---@field quit? "close"|"wait"|"continue" How the new pane quit. "close" will close the pane if the command finished. "wait" will wait an enter key. "continue" will start the interactive shell after it. Default: "close"

---@param command string[]
---@param opts? kyoh86.lib.tmux.RunOptions
function M.run(command, opts)
	if not vim.env.TMUX then
		return
	end

	opts = opts or {}

	local list = {
		vim.fn.shellescape(vim.env.SHELL or "zsh"),
		"-li",
	}
	if #command > 0 then
		if opts.quit == "wait" then
			command =
				vim.list_extend(command, { ";", "echo", vim.fn.shellescape("Press Enter key to quit"), ";", "read" })
		end
		if opts.quit == "continue" then
			command = vim.list_extend(command, { ";", "zsh", "-li" })
		end
		table.insert(list, "-c")
		table.insert(list, vim.fn.shellescape(table.concat(command, " ")))
	end

	local shellCommand = table.concat(list, " ")

	local result =
		vim.system({ "tmux", "split-window", opts.split == "horizontal" and "-h" or "-v", "-b", shellCommand }):wait()
	return result.code
end

return M
