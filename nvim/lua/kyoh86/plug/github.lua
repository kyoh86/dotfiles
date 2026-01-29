---@type LazySpec
local spec = {
  "kyoh86/denops-github.vim",
  config = function()
    local au = require("kyoh86.lib.autocmd")
    au.group("kyoh86.plug.github", true):hook("FileType", {
      pattern = "github-issue-view",
      callback = function(ev)
        local opt = {
          buffer = ev.buf,
          nowait = true,
          silent = true,
        }
        vim.keymap.set("n", "<leader>n", "<Plug>(denops-github-issue-viewer-next)", opt)
        vim.keymap.set("n", "<leader>p", "<Plug>(denops-github-issue-viewer-prev)", opt)
        vim.keymap.set("n", "<leader>e", "<Plug>(denops-github-issue-viewer-edit-cursor)", opt)
        vim.keymap.set("n", "<leader>c", "<Plug>(denops-github-issue-viewer-new-comment)", opt)
        vim.keymap.set("n", "<leader>b", "<Plug>(denops-github-issue-viewer-browse-cursor)", opt)
      end,
    })
  end,
}
return spec
