---@type LazySpec
local spec = {
  "vim-denops/denops.vim",
  config = function(plugin)
    -- vim.g["denops#debug"] = 1
    vim.env.DENOPS_TEST_DENOPS_PATH = plugin.dir
    vim.g["denops#server#deno_args"] = { "-q", "--no-lock", "-A", "--unstable-kv" }
  end,
}
return spec
