-- pane_test.lua
-- pane のテストスクリプト

-- ランタイムパスを追加
vim.cmd("set rtp+=/home/kyoh86/Projects/github.com/kyoh86/dotfiles/.worktree/tmux/nvim")

local pane = require("kyoh86.lib.pane")

-- 単純なレイアウトでテスト
local function test_simple()
  print("=== Test 1: Simple row ===")
  vim.cmd("only") -- 全てのウィンドウを閉じて1つにする

  -- row(pane1, pane2) を作成
  vim.cmd("vsplit")
  local wins = vim.api.nvim_list_wins()
  vim.api.nvim_win_set_buf(wins[1], vim.fn.bufadd("test1.txt"))
  vim.api.nvim_win_set_buf(wins[2], vim.fn.bufadd("test2.txt"))
  vim.fn.bufload(vim.api.nvim_win_get_buf(wins[1]))
  vim.fn.bufload(vim.api.nvim_win_get_buf(wins[2]))

  local layout1 = pane.get()
  print("Original: " .. vim.fn.json_encode(layout1))

  pane.reset_and_apply(layout1)

  local layout2 = pane.get()
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
  vim.cmd("vsplit") -- 左右に分割
  vim.api.nvim_set_current_win(vim.api.nvim_list_wins()[1]) -- 左に移動
  vim.cmd("split") -- 左を上下に分割

  local wins = vim.api.nvim_list_wins()
  vim.api.nvim_win_set_buf(wins[1], vim.fn.bufadd("test1.txt"))
  vim.api.nvim_win_set_buf(wins[2], vim.fn.bufadd("test2.txt"))
  vim.api.nvim_win_set_buf(wins[3], vim.fn.bufadd("test3.txt"))
  for _, win in ipairs(wins) do
    vim.fn.bufload(vim.api.nvim_win_get_buf(win))
  end

  local layout1 = pane.get()
  print("Original: " .. vim.fn.json_encode(layout1))

  pane.reset_and_apply(layout1)

  local layout2 = pane.get()
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

  vim.cmd("split") -- 上下に分割（1と2）
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
  local buf_names = { "test1.txt", "test2.txt", "test3.txt", "test4.txt", "test5.txt" }
  for i, win in ipairs(wins) do
    if buf_names[i] then
      local buf = vim.fn.bufadd(buf_names[i])
      vim.fn.bufload(buf)
      vim.api.nvim_win_set_buf(win, buf)
    end
  end

  local layout1 = pane.get()
  print("Original: " .. vim.fn.json_encode(layout1))

  pane.reset_and_apply(layout1)

  local layout2 = pane.get()
  print("Restored: " .. vim.fn.json_encode(layout2))

  if vim.fn.json_encode(layout1) == vim.fn.json_encode(layout2) then
    print("✓ PASSED")
  else
    print("✗ FAILED")
  end
end

-- 同方向の分割をテスト（ユーザーの例）
local function test_same_direction()
  print("\n=== Test 4: Same direction row(row(1,2), 3) ===")
  vim.cmd("only")

  -- 手動でレイアウトを作成してから取得
  vim.cmd("vsplit") -- 左右に分割（1と2）
  vim.api.nvim_set_current_win(vim.api.nvim_list_wins()[1]) -- 左に移動
  vim.cmd("vsplit") -- 左を左右に分割（1と2）

  local wins = vim.api.nvim_list_wins()
  vim.api.nvim_win_set_buf(wins[1], vim.fn.bufadd("test11.txt"))
  vim.api.nvim_win_set_buf(wins[2], vim.fn.bufadd("test10.txt"))
  vim.api.nvim_win_set_buf(wins[3], vim.fn.bufadd("test1.txt"))
  for _, win in ipairs(wins) do
    vim.fn.bufload(vim.api.nvim_win_get_buf(win))
  end

  -- サイズを設定
  vim.api.nvim_set_current_win(wins[1])
  vim.cmd("vertical resize 40")
  vim.api.nvim_set_current_win(wins[2])
  vim.cmd("vertical resize 26")
  vim.api.nvim_set_current_win(wins[3])
  vim.cmd("vertical resize 12")

  -- レイアウトを取得
  local layout = pane.get()

  print("Original: " .. vim.fn.json_encode(layout))

  pane.reset_and_apply(layout)

  local layout2 = pane.get()
  print("Restored: " .. vim.fn.json_encode(layout2))

  if vim.fn.json_encode(layout) == vim.fn.json_encode(layout2) then
    print("✓ PASSED")
  else
    print("✗ FAILED")
    print("Expected width: first.first=" .. (layout.first and layout.first.width or "nil") .. ", first=" .. (layout.width or "nil"))
    print("Got width: first.first=" .. (layout2.first and layout2.first.width or "nil") .. ", first=" .. (layout2.width or "nil"))
  end
end

-- 手動で同方向の分割を作るテスト
local function test_same_direction_manual()
  print("\n=== Test 5: Manual same direction row(row(1,2), 3) ===")
  vim.cmd("only")

  -- row(row(1,2), 3) を作成
  vim.cmd("vsplit") -- 左右に分割（1と2）
  vim.api.nvim_set_current_win(vim.api.nvim_list_wins()[1]) -- 左に移動
  vim.cmd("vsplit") -- 左を左右に分割（1と2）

  local wins = vim.api.nvim_list_wins()
  vim.api.nvim_win_set_buf(wins[1], vim.fn.bufadd("test1.txt"))
  vim.api.nvim_win_set_buf(wins[2], vim.fn.bufadd("test2.txt"))
  vim.api.nvim_win_set_buf(wins[3], vim.fn.bufadd("test3.txt"))
  for _, win in ipairs(wins) do
    vim.fn.bufload(vim.api.nvim_win_get_buf(win))
  end

  local layout1 = pane.get()
  print("Original: " .. vim.fn.json_encode(layout1))

  pane.reset_and_apply(layout1)

  local layout2 = pane.get()
  print("Restored: " .. vim.fn.json_encode(layout2))

  if vim.fn.json_encode(layout1) == vim.fn.json_encode(layout2) then
    print("✓ PASSED")
  else
    print("✗ FAILED")
  end
end

-- :new | new | new | vnew | wincmd j | vnew | new コマンドで作成したレイアウトのテスト
-- TODO: 深くネストされた同方向分割のサイズ再現問題を解決する必要がある
local function test_cmd_layout()
  print("\n=== Test 6: Command layout (:new | new | new | vnew | wincmd j | vnew | new) ===")
  vim.cmd("only")

  -- ユーザーのコマンドでレイアウトを作成
  vim.cmd("new")
  vim.cmd("new")
  vim.cmd("new")
  vim.cmd("vnew")
  vim.cmd("wincmd j")
  vim.cmd("vnew")
  vim.cmd("new")

  -- バッファ名を設定（一意な名前を使用）
  local wins = vim.api.nvim_list_wins()
  for i, win in ipairs(wins) do
    local buf = vim.fn.bufadd("test_cmd_" .. i .. ".txt")
    vim.fn.bufload(buf)
    vim.api.nvim_win_set_buf(win, buf)
  end

  -- レイアウトを取得（dump）
  local layout1 = pane.get()
  print("Original: " .. vim.fn.json_encode(layout1))

  -- リセットしてロード
  pane.reset_and_apply(layout1)

  -- レイアウトを再取得（dump）
  local layout2 = pane.get()
  print("Restored: " .. vim.fn.json_encode(layout2))

  -- 比較
  if vim.fn.json_encode(layout1) == vim.fn.json_encode(layout2) then
    print("✓ PASSED")
  else
    print("✗ FAILED (TODO: Fix deeply nested same-direction splits)")
  end
end

-- テストを実行
test_simple()
test_nested()
test_complex()
test_same_direction()
test_same_direction_manual()
test_cmd_layout()
