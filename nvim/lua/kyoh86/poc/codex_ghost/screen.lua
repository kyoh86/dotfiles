local M = {}

local ghost_ns = vim.api.nvim_create_namespace("kyoh86-codex-ghost")
local ghost_hl = "CodexGhost"

function M.setup()
  vim.api.nvim_set_hl(0, ghost_hl, { link = "Comment", default = true })
end

function M.clear(buf)
  if buf and vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.api.nvim_buf_clear_namespace, buf, ghost_ns, 0, -1)
  end
end

--- Show ghost lines on the cursor
--- @param pos codex_ghost.Position|nil
--- @param lines string[]
--- @param opts {color?: "never"}?
function M.show_ghost(pos, lines, opts)
  opts = opts or {}
  if not pos then
    return
  end
  if #lines == 0 then
    return
  end

  local virt_lines = {}
  if opts.color and opts.color == "never" then
    for _, line in ipairs(lines) do
      virt_lines[#virt_lines + 1] = { { line, "Normal" } }
    end
  else
    for _, line in ipairs(lines) do
      virt_lines[#virt_lines + 1] = { { line, ghost_hl } }
    end
  end

  vim.api.nvim_buf_set_extmark(pos.buf, ghost_ns, pos.row, 0, {
    virt_lines = virt_lines,
    virt_lines_above = false,
    hl_mode = "combine",
    priority = 200,
  })
end

--- Put lines under the cursor
--- @param pos codex_ghost.Position
--- @param lines string[]
function M.insert_lines(pos, lines)
  if not pos then
    return
  end
  if #lines == 0 then
    return
  end

  vim.api.nvim_buf_set_lines(pos.buf, pos.row + 1, pos.row + 1, false, lines)
end

--- Show pending message
--- @param pos codex_ghost.Position
--- @param message string
function M.show_pending(pos, message)
  if not message or message == "" then
    return
  end
  if not vim.api.nvim_buf_is_valid(pos.buf) then
    return
  end
  vim.api.nvim_buf_set_extmark(pos.buf, ghost_ns, pos.row, 0, {
    virt_text = { { message, ghost_hl } },
    virt_text_pos = "eol",
    hl_mode = "combine",
    priority = 50,
  })
end

return M
