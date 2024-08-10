--- 外部ファイルを開く方法を設定する
local glaze = require("kyoh86.glaze")
glaze.glaze("opener", function()
  if vim.fn.executable("wslview") ~= 0 then
    return "wslview"
  elseif vim.fn.executable("xdg-open") ~= 0 then
    return "xdg-open"
  end
  return ""
end)

--- カーソル下のファイルを関連付けられた外部ファイルで開いたりする
local function open_cursor()
  local target = vim.fn.expand("<cfile>")
  if target == nil then
    print("No target found at cursor.")
    return
  end
  target = string.gsub(target --[[@as string]], [[\.+$]], "")
  if string.match(target, "^#%d+$") then
    vim.print("opening GitHub Issue " .. target)
    -- target が #nnn というIssue番号の場合は、gh を呼んでIssueを開く
    local cmd = { "gh", "issue", "view", "--web", target:sub(2) }
    vim.fn.jobstart(cmd, {
      on_exit = function(_, code)
        if code ~= 0 then
          print("Failed to open issue.")
        end
      end,
    })
  elseif string.match(target, "^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$") then
    vim.print("opening GitHub Repo " .. target)
    -- targetがowner/repoの形ならgh を呼んでリポジトリを開く
    local cmd = { "gh", "repo", "view", "--web", target }
    vim.fn.jobstart(cmd, {
      on_exit = function(_, code)
        if code ~= 0 then
          print("Failed to open repository.")
        end
      end,
    })
  else
    local repo, number = string.match(target, "^([a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+)#(%d+)$")
    if repo and number then
      vim.print("opening GitHub Issue " .. target)
      -- targetがowner/repo#nnnの形ならgh を呼んで指定のリポジトリのIssueを開く
      local cmd = { "gh", "issue", "view", "--repo", repo, "--web", number }
      vim.fn.jobstart(cmd, {
        on_exit = function(_, code)
          if code ~= 0 then
            vim.print("Failed to open issue.")
            vim.print(repo, number)
          end
        end,
      })
    else
      vim.print("opening " .. target)
      vim.ui.open(target)
    end
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
