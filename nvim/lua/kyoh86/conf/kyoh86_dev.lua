--- integrations for kyoh86.dev

local Kyoh86DevAugroup = "Kyoh86DevAugroup"

local group = vim.api.nvim_create_augroup(Kyoh86DevAugroup, { clear = true })

local function ascii_name(s)
  local hash = vim.system({ "sha256sum" }, { stdin = s, text = true }):wait().stdout:sub(1, 8)
  return ("%s"):format(hash)
end

vim.api.nvim_create_autocmd("DirChanged", {
  group = group,
  pattern = "*",
  callback = function(ev)
    local path = ev.file
    vim.print(path)
    if vim.startswith(path, "/home/kyoh86/dev/gh/kyoh86/kyoh86.dev/") then
      vim.print("Entered to kyoh86.dev")
      vim.api.nvim_create_user_command("Kyoh86DevNewArticle", function()
        local today = os.date("%Y-%m-%d")
        vim.ui.input({ prompt = "Title: " }, function(title)
          local hash = ascii_name(title)
          local name = today .. "_" .. hash
          vim.cmd.edit("src/content/posts/" .. name .. ".md")
          vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            [[---]],
            [[title: "]] .. title .. [["]],
            [[description: ""]],
            [[pubDate: ]] .. today,
            [[tags: [""]] .. "]",
            [[draft: true]],
            [[# cover: "./]] .. name .. [[/cover.png" # 1200 x 630 px only]],
            [[---]],
            "",
          })
          vim.api.nvim_win_set_cursor(0, { 7, 0 })
        end)
      end, { desc = "kyoh86.dev用の記事を追加する" })
    else
      pcall(vim.api.nvim_del_user_command, "Kyoh86DevNewArticle")
    end
  end,
})
