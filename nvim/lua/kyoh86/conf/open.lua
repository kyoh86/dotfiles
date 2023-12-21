--- カーソル下のファイルを関連付けられた外部ファイルで開いたりする
local function open_cursor()
  local target = vim.fn.expand("<cfile>")
  if target == nil then
    print("No target found at cursor.")
    return
  end
  target = string.gsub(target --[[@as string]], [[\.+$]], "")
  -- target が #nnn というIssue番号の場合は、そのIssueを開く
  if string.match(target, "^#%d+$") then
    -- gh を呼んでIssueを開く
    local cmd = { "gh", "issue", "view", "--web", target:sub(2) }
    vim.fn.jobstart(cmd, {
      on_exit = function(_, code)
        if code ~= 0 then
          print("Failed to open issue.")
        end
      end,
    })
  elseif string.match(target, "^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$") then
    -- gh を呼んでリポジトリを開く
    local cmd = { "gh", "repo", "view", "--web", target }
    vim.fn.jobstart(cmd, {
      on_exit = function(_, code)
        if code ~= 0 then
          print("Failed to open repository.")
        end
      end,
    })
  else
    vim.ui.open(target)
  end
end

vim.api.nvim_create_user_command("OpenCursor", open_cursor, {
  desc = "Open files or urls under the cursor by special handler",
})
vim.keymap.set("n", "<plug>(open-cursor-file)", open_cursor, {
  desc = "Open files or urls under the cursor by special handler",
  silent = true,
  remap = false,
  nowait = true,
})

vim.keymap.set("n", "gx", "<plug>(open-cursor-file)", { desc = "Open files or urls under the cursor by special handler" })

vim.keymap.set("n", "gf", "gF", { remap = true })
vim.keymap.set("n", "gfv", [[<cmd>vertical wincmd F<cr>]], { remap = false })
vim.keymap.set("n", "gfx", [[<cmd>horizontal wincmd F<cr>]], { remap = false })
