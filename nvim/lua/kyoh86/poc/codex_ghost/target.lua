local M = {}

--- @class codex_ghost.Target A buffer to get suggestion from Agent
--- @field collect_context fun(self: codex_ghost.Target)
--- @field apply fun(self: codex_ghost.Target, suggestion: string[])

--- @param buf integer Buffer id, or 0 for current buffer
--- @param row integer
--- @param col integer
--- @param opts codex_ghost.Config
--- @return codex_ghost.Target
function M.new(buf, row, col, opts)
  local instance = {
    buf = buf,
    tick = vim.api.nvim_buf_get_changedtick(buf),
    row = row,
    col = col,
    opts = opts,
  }
  setmetatable(instance, { __index = M })
  return instance
end

--- Collect context from the buffer
--- @return codex_ghost.Context|nil
function M:collect_context()
  local line_count = vim.api.nvim_buf_line_count(self.buf)
  local current_line = vim.api.nvim_buf_get_lines(self.buf, self.row, self.row + 1, false)[1]
  -- If the cursor is on an empty line at the end of the buffer, there's no context.
  if self.row >= line_count and (current_line == nil or current_line == "") then
    return nil
  end

  local before_start = math.max(0, self.row - self.opts.context_before)
  local before = vim.api.nvim_buf_get_lines(self.buf, before_start, self.row, false)

  local after_end = math.min(line_count, self.row + 1 + self.opts.context_after)
  local after = vim.api.nvim_buf_get_lines(self.buf, self.row + 1, after_end, false)

  return {
    before = before,
    line = current_line or "",
    after = after,
    pos = {
      buf = self.buf,
      row = self.row,
      col = self.col,
    },
    filename = vim.api.nvim_buf_get_name(self.buf),
    filetype = vim.bo[self.buf].filetype,
  }
end

--- Apply suggestion to the buffer.
---
--- @param suggestion string[]
--- @return nil|string result if the error is found, return it.
function M:apply(suggestion)
  if not vim.api.nvim_buf_is_valid(self.buf) then
    return "invalid buffer"
  end
  if vim.api.nvim_buf_get_changedtick(self.buf) ~= self.tick then
    local yesno = vim.fn.confirm("There're lines which changed while I think. Sure you want to apply the suggestion?: ", "&Yes\n&No")
    if yesno ~= 1 then
      return "conflict"
    end
  end
  local curr_lines = vim.api.nvim_buf_get_lines(self.buf, 0, -1, false)
  local insert_at = math.min(self.row + 1, #curr_lines)
  local ok, err = pcall(vim.api.nvim_buf_set_lines, self.buf, insert_at, insert_at, false, suggestion)
  if not ok then
    return err
  end
  return nil
end

return M
