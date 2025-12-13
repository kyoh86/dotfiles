local M = {}

--- @class codex_ghost.Target A buffer to get suggestion from Agent

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
  setmetatable(instance, M)
  return instance
end

--- Collect context from the buffer
function M:collect_context()
  local lines = vim.api.nvim_buf_get_lines(self.buf, 0, -1, true)
  local cur_line = lines[self.row + 1] or ""
  if cur_line == "" and self.row >= #lines then
    return nil, nil
  end
  local before_cursor = cur_line:sub(1, self.col)
  local after_cursor = cur_line:sub(self.col + 1)

  local before = {}
  local before_start = math.max(0, self.row - self.opts.context_before)
  for i = before_start + 1, self.row do
    before[#before + 1] = lines[i]
  end
  before[#before + 1] = before_cursor

  local after = { after_cursor }
  local after_end = math.min(#lines, self.row + self.opts.context_after + 1)
  for i = self.row + 2, after_end do
    after[#after + 1] = lines[i]
  end

  return table.concat(before, "\n"), table.concat(after, "\n")
end

--- Apply suggestion to the buffer.
---
--- @param suggestion string[]
--- @return nil|string result if the error is found, return it.
function M:apply(suggestion)
  if not vim.api.nvim_buf_is_valid(self.buf) then
    return "invalid buffer"
  end
  if vim.api.nvim_buf_get_changedtick(self.buf) ~= self.base_tick then
    local yesno = vim.fn.confirm("There're lines which changed while I think. Sure you want to apply the suggestion?: ", "&Yes\n&No")
    if yesno == 1 then --yes
    elseif yesno == 2 then -- no
      return "conflict"
    else -- cancel
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
