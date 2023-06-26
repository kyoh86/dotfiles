---@type LazySpec[]
local spec = {
  {
    "Shougo/ddu.vim",
    config = function()
      kyoh86.fa.ddu.custom.patch_global({
        sourceOptions = {
          _ = {
            ignoreCase = true,
          },
        },
      })
    end,
    dependencies = { "vim-denops/denops.vim" },
  },
  { import = "kyoh86.plug.ddu.source" },
  { import = "kyoh86.plug.ddu.filter" },
  { import = "kyoh86.plug.ddu.kind" },
  { import = "kyoh86.plug.ddu.ui" },
  -- TODO: "<leader>fgi", gh.issues() -- "find an issue from GitHub with Telescope"
  -- TODO: "<leader>fgp", gh.pull_request() -- "find a pull-request from GitHub with Telescope"
}
return spec
