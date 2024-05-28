---@type LazySpec
local spec = {
  "vim-denops/denops.vim",
  config = function(plugin)
    -- vim.g["denops#debug"] = 1
    vim.env.DENOPS_TEST_DENOPS_PATH = plugin.dir
    vim.g["denops#server#deno_args"] = { "-q", "--no-lock", "-A", "--unstable-kv" }
    local group = vim.api.nvim_create_augroup("kyoh86-plug-denops-deno-cache", { clear = true })
    vim.api.nvim_create_autocmd("User", {
      group = group,
      pattern = { "LazyInstall", "LazyUpdate" },
      callback = function()
        vim.system({ "deno", "cache", kyoh86.lazydir("*/denops/**/*.ts") })
        vim.notify("denops dependencies cached", vim.log.levels.INFO)
      end,
    })
  end,
}
return spec
