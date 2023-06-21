---@type LazySpec[]
local spec = {
  {
    "Shougo/ddu.vim",
    config = function()
      vim.fa.ddu.custom.patch_global({
        sourceOptions = {
          _ = {
            ignoreCase = true,
          },
        },
      })
    end,
    dependencies = { "vim-denops/denops.vim" },
  },
  { import = "kyoh86.plug.ddu.ui-ff" },
  { import = "kyoh86.plug.ddu.filter-fzf" },
  { import = "kyoh86.plug.ddu.filter-fuse" },
  { import = "kyoh86.plug.ddu.source-file" },
  { import = "kyoh86.plug.ddu.source-help" },
  { import = "kyoh86.plug.ddu.kind-file" },
  { import = "kyoh86.plug.ddu.source-command" },
  { import = "kyoh86.plug.ddu.source-command_history" },
  { import = "kyoh86.plug.ddu.source-git" },
  { import = "kyoh86.plug.ddu.source-lsp" },
  { import = "kyoh86.plug.ddu.source-mr" },
  { import = "kyoh86.plug.ddu.source-buffer" },
  { import = "kyoh86.plug.ddu.source-emoji" },
  { import = "kyoh86.plug.ddu.source-quickfix" },
  { import = "kyoh86.plug.ddu.source-gogh" },
  { import = "kyoh86.plug.ddu.source-lazy_nvim" },
  -- TODO: "<leader>fgi", gh.issues() -- "find an issue from GitHub with Telescope"
  -- TODO: "<leader>fgp", gh.pull_request() -- "find a pull-request from GitHub with Telescope"
}
return spec
