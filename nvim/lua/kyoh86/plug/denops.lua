---@type LazySpec
local spec = {
  "vim-denops/denops.vim",
  config = function(plugin)
    -- vim.g["denops#debug"] = 1
    vim.env.DENOPS_TEST_DENOPS_PATH = plugin.dir
  end,
}
return spec
