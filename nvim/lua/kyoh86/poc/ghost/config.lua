local M = {}

--- @class ghost.Config
--- @field context_before integer
--- @field context_after integer
--- @field model string|nil
--- @field max_lines integer
--- @field disable_filetypes string[]
--- @field disable_buftypes string[]
--- @field timeout_ms integer
--- @field log_file string|nil
--- @field pending_text string
--- @field notify_on_cancel boolean

--- @type ghost.Config
local defaults = {
  context_before = 120,
  context_after = 60,
  model = "gpt-5.1-codex-mini",
  max_lines = 4000,
  disable_filetypes = {},
  disable_buftypes = { "help", "prompt", "quickfix", "terminal" },
  timeout_ms = 50000,
  log_file = nil, -- e.g. "/tmp/ghost.log"
  pending_text = "⏳ Codex",
  notify_on_cancel = true,
}

function M.setup(opts)
  return vim.tbl_extend("force", defaults, opts or {})
end

return M
