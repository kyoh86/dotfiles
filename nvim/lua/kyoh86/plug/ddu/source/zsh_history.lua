local helper = require("kyoh86.plug.ddu.helper")
local function tmux_paste(args)
  if not vim.env.TMUX then
    vim.notify("tmux の外では zsh history を送れません", vim.log.levels.WARN)
    return 0
  end

  local commands = {}
  for _, item in ipairs(args.items or {}) do
    local command = vim.tbl_get(item, "action", "command")
    if command ~= nil and command ~= "" then
      table.insert(commands, command)
    end
  end
  if #commands == 0 then
    return 0
  end

  local params = args.actionParams or {}
  local target = params.target or "!"
  local buffer = "ddu-zsh-history"
  local text = table.concat(commands, "\n")

  local load = vim.system({ "tmux", "load-buffer", "-b", buffer, "-" }, { stdin = text, text = true }):wait()
  if load.code ~= 0 then
    vim.notify(("tmux load-buffer failed: %s"):format(vim.trim(load.stderr or "")), vim.log.levels.ERROR)
    return load.code
  end

  local paste = vim.system({ "tmux", "paste-buffer", "-d", "-p", "-t", target, "-b", buffer }, { text = true }):wait()
  if paste.code ~= 0 then
    vim.notify(("tmux paste-buffer failed: %s"):format(vim.trim(paste.stderr or "")), vim.log.levels.ERROR)
    return paste.code
  end

  vim.system({ "tmux", "select-pane", "-t", target }):wait()
  return paste.code
end

---@type LazySpec
local spec = {
  "kyoh86/ddc-source-zsh-history", -- It also contains the source of the ddu plugin.
  dependencies = { "ddu.vim", "lazy.nvim" },
  config = function()
    vim.fn["ddu#custom#action"]("kind", "zsh_history", "custom:tmux-paste", tmux_paste)

    helper.setup("zsh_history", {
      sources = { {
        name = "zsh_history",
        options = {
          matchers = { "matcher_fzf" },
          sorters = { "sorter_fzf" },
        },
      } },
      kindOptions = { zsh_history = { defaultAction = "append" } },
    }, {
      start = { {
        modes = "t",
        key = "<c-x>y",
        desc = "ZSH History",
      }, {
        modes = "t",
        key = "<c-x><c-y>",
        desc = "ZSH History",
      } },
    })
    helper.setup("zsh_history_tmux", {
      sources = { {
        name = "zsh_history",
        options = {
          matchers = { "matcher_fzf" },
          sorters = { "sorter_fzf" },
        },
      } },
      kindOptions = { zsh_history = { defaultAction = "custom:tmux-paste" } },
    }, {
      -- start this one from zsh keymap (<C-x><C-r>)
      localmap = {
        ["<leader>p"] = { action = "itemAction", params = { name = "custom:tmux-paste" } },
      },
    })
  end,
}
return spec
