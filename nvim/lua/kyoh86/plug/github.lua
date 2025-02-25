---@type LazySpec
local spec = {
  "kyoh86/denops-github.vim",
  config = function()
    vim.api.nvim_create_autocmd("FileType", {
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
