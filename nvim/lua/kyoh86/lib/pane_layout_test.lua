-- pane_layout_test.lua
-- pane_layout のテストスクリプト

-- ランタイムパスを追加
vim.cmd("set rtp+=/home/kyoh86/Projects/github.com/kyoh86/dotfiles/.worktree/tmux/nvim")

local pane_layout = require("kyoh86.lib.pane_layout")

-- 単純なレイアウトでテスト
local function test_simple()
  print("=== Test 1: Simple row ===")
  vim.cmd("only")  -- 全てのウィンドウを閉じて1つにする

  -- row(pane1, pane2) を作成
  vim.cmd("vsplit")
  local wins = vim.api.nvim_list_wins()
  vim.api.nvim_win_set_buf(wins[1], vim.fn.bufadd("test1.txt"))
  vim.api.nvim_win_set_buf(wins[2], vim.fn.bufadd("test2.txt"))
  vim.fn.bufload(vim.api.nvim_win_get_buf(wins[1]))
  vim.fn.bufload(vim.api.nvim_win_get_buf(wins[2]))

  local layout1 = pane_layout.get()
  print("Original: " .. vim.fn.json_encode(layout1))

  vim.cmd("only")  -- リセット
  pane_layout.reset_and_apply(layout1)

  local layout2 = pane_layout.get()
  print("Restored: " .. vim.fn.json_encode(layout2))

  if vim.fn.json_encode(layout1) == vim.fn.json_encode(layout2) then
    print("✓ PASSED")
  else
    print("✗ FAILED")
  end
end

-- もう少し複雑なレイアウトでテスト
local function test_nested()
  print("\n=== Test 2: Nested row(col(1,2), 3) ===")
  vim.cmd("only")

  -- row(col(1,2), 3) を作成
  vim.cmd("vsplit")  -- 左右に分割
  vim.api.nvim_set_current_win(vim.api.nvim_list_wins()[1])  -- 左に移動
  vim.cmd("split")   -- 左を上下に分割

  local wins = vim.api.nvim_list_wins()
  vim.api.nvim_win_set_buf(wins[1], vim.fn.bufadd("test1.txt"))
  vim.api.nvim_win_set_buf(wins[2], vim.fn.bufadd("test2.txt"))
  vim.api.nvim_win_set_buf(wins[3], vim.fn.bufadd("test3.txt"))
  for _, win in ipairs(wins) do
    vim.fn.bufload(vim.api.nvim_win_get_buf(win))
  end

  local layout1 = pane_layout.get()
  print("Original: " .. vim.fn.json_encode(layout1))

  vim.cmd("only")
  pane_layout.reset_and_apply(layout1)

  local layout2 = pane_layout.get()
  print("Restored: " .. vim.fn.json_encode(layout2))

  if vim.fn.json_encode(layout1) == vim.fn.json_encode(layout2) then
    print("✓ PASSED")
  else
    print("✗ FAILED")
  end
end

-- さらに複雑なレイアウトでテスト（ユーザーの例）
local function test_complex()
  print("\n=== Test 3: Complex col(row(col(row(7,6), col(10,8)), 4), 9), 1) ===")
  vim.cmd("only")

  -- 手動で複雑なレイアウトを作成
  -- col(row(col(row(7,6), col(10,8)), 4), 9), 1
  -- 簡易版: col(col(row(7,6), col(10,8)), 1)

  vim.cmd("split")  -- 上下に分割（1と2）
  vim.cmd("vsplit") -- 上を左右に分割

  local wins = vim.api.nvim_list_wins()
  -- 左上をさらに分割
  vim.api.nvim_set_current_win(wins[2])
  vim.cmd("split")

  wins = vim.api.nvim_list_wins()
  -- 右上を左右に分割
  vim.api.nvim_set_current_win(wins[3])
  vim.cmd("vsplit")

  -- バッファを設定
  wins = vim.api.nvim_list_wins()
  local buf_names = {"test1.txt", "test2.txt", "test3.txt", "test4.txt", "test5.txt"}
  for i, win in ipairs(wins) do
    if buf_names[i] then
      local buf = vim.fn.bufadd(buf_names[i])
      vim.fn.bufload(buf)
      vim.api.nvim_win_set_buf(win, buf)
    end
  end

  local layout1 = pane_layout.get()
  print("Original: " .. vim.fn.json_encode(layout1))

  vim.cmd("only")
  pane_layout.reset_and_apply(layout1)

  local layout2 = pane_layout.get()
  print("Restored: " .. vim.fn.json_encode(layout2))

  if vim.fn.json_encode(layout1) == vim.fn.json_encode(layout2) then
    print("✓ PASSED")
  else
    print("✗ FAILED")
  end
end

-- テストを実行
test_simple()
test_nested()
test_complex()
