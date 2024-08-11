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
        vim.fn["denops#cache#update"]({ reload = true })
        vim.notify("denops dependencies cached", vim.log.levels.INFO)
      end,
    })
    vim.api.nvim_create_user_command("DenopsCacheUpdate", [[call denops#cache#update({"reload": v:true})]], {})
  end,
}
return spec
