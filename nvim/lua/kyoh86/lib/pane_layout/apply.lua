---@class kyoh86.lib.pane_layout.apply.Windows
---@field node Node
---@field win number
---@field first? kyoh86.lib.pane_layout.apply.Windows
---@field second? kyoh86.lib.pane_layout.apply.Windows

local M = {}

---ウィンドウ構造を構築する（サイズ設定はしない）
---@param node Node
---@param win number
---@return kyoh86.lib.pane_layout.apply.Windows
local function create_windows(node, win)
  if node.kind == "pane" then
    -- 葉: parent_win にバッファを設定
    if node.buffer then
      vim.api.nvim_win_set_buf(win, node.buffer)
    end
    return { node = node, win = win }
  else
    vim.api.nvim_set_current_win(win)
    if node.kind == "col" then
      vim.cmd("belowright split")
    else
      vim.cmd("belowright vsplit")
    end
    local new_win = vim.api.nvim_get_current_win()

    -- first を構築
    local first_result = create_windows(node.first, win)

    -- second を構築
    local second_result = create_windows(node.second, new_win)

    return { node = node, win = win, first = first_result, second = second_result }
  end
end

---すべてのペインのサイズを再帰的に設定
---@param panes kyoh86.lib.pane_layout.apply.Windows
local function apply_size(panes)
  if not panes or not panes.node then
    return
  end

  if panes.node.kind == "pane" then
    -- ペインのサイズを設定
    vim.api.nvim_set_current_win(panes.win)
    vim.cmd("resize " .. panes.node.height)
    vim.cmd("vertical resize " .. panes.node.width)
  else
    -- row/colノード: 子を処理
    if panes.first then
      apply_size(panes.first)
    end
    if panes.second then
      apply_size(panes.second)
    end
  end
end

---@param node Node
---@param win number
function M.apply(node, win)
  local panes = create_windows(node, win)
  apply_size(panes)
end

return M
