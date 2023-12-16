--- バッファと位置を指定して、部分的にmodifiableを切り替える処理群
--- extmarksを使っているので、vim 8.1.1560以上が必要

---- バッファ変数に独自の名前の値を保存する
--- @param bufnr number バッファ番号
--- @param name string 変数名
--- @param value any 値
local function set_buf_var(bufnr, name, value)
  vim.api.nvim_buf_set_var(bufnr, "partial_modifiable#" .. name, value)
end

---- バッファ変数から独自の名前の値を取得する
--- @param bufnr number バッファ番号
--- @param name string 変数名
--- @return any
local function get_buf_var(bufnr, name, default)
  local ok, ret = pcall(vim.api.nvim_buf_get_var, bufnr, "partial_modifiable#" .. name)
  if ok then
    return ret
  end
  return default
end

---- バッファ変数にextmarkのidとmodifiableの状態を保存する
--- @param bufnr number バッファ番号
--- @param id number extmarkのid
--- @param modifiable boolean modifiableの状態
--- @return nil
local function set_buf_partial_modifiable(bufnr, id, modifiable)
  set_buf_var(bufnr, id --[[@as string]], modifiable)
end

--- バッファ変数からextmarkのidを使ってmodifiableの状態を取得する
--- @param bufnr number バッファ番号
--- @param id number extmarkのid
--- @return boolean
local function get_buf_partial_modifiable(bufnr, id)
  return get_buf_var(bufnr, id --[[@as string]], true)
end

local function get_or_create_ns()
  if vim.g.partial_modifiable_ns == nil then
    vim.g.partial_modifiable_ns = vim.api.nvim_create_namespace("partial_modifiable")
  end
  return vim.g.partial_modifiable_ns
end

--- イベントハンドラを登録する
--- @param bufnr number
local function register_event(bufnr)
  local group = vim.api.nvim_create_augroup("partial_modifiable", { clear = true })
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = group,
    pattern = "<buffer=" .. bufnr .. ">",
    command = "lua require('kyoh86.poc.partial_modifiable').cursor_moved()",
  })
end

--- バッファの指定位置のmodifiableを切り替える
--- @param bufnr number
--- @param line number
--- @param col number
--- @param end_line number
--- @param end_col number
--- @param modifiable boolean
--- @return number
local function set_extmark(bufnr, line, col, end_line, end_col, modifiable)
  if get_buf_var(bufnr, "marked", false) ~= true then
    register_event(bufnr)
    set_buf_var(bufnr, "marked", true)
  end
  local id = vim.api.nvim_buf_set_extmark(bufnr, get_or_create_ns(), line, col, {
    end_line = end_line,
    end_col = end_col,
  })
  set_buf_partial_modifiable(bufnr, id, modifiable)
  return id
end

--- CursorMovedで呼び出して、カーソル位置のmodifiableを切り替える
local function cursor_moved()
  local buf = vim.api.nvim_get_current_buf()
  local pos = vim.api.nvim_win_get_cursor(0)
  local line, col = pos[1], pos[2]
  local marks = vim.api.nvim_buf_get_extmarks(buf, get_or_create_ns(), { line, col }, { line, col + 1 }, { overlap = true })
  for _, mark in ipairs(marks) do
    local id = mark[1]
    local modifiable = get_buf_partial_modifiable(buf, id)
    if modifiable ~= nil then
      vim.api.nvim_set_option_value("modifiable", modifiable, { buf = buf })
      return
    end
  end
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
end

return {
  set_extmark = set_extmark,
  cursor_moved = cursor_moved,
}
