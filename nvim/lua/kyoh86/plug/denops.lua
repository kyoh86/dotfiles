---@type LazySpec
local spec = {
  "vim-denops/denops.vim",
  config = function(plugin)
    -- vim.g["denops#debug"] = 1
    vim.env.DENOPS_TEST_DENOPS_PATH = plugin.dir
    vim.g["denops#server#deno_args"] = { "-q", "--no-lock", "-A", "--unstable-kv" }

    local au = require("kyoh86.lib.autocmd")
    au.group("kyoh86.plug.denops", true):hook("User", {
      pattern = { "LazyInstall", "LazyUpdate" },
      callback = function()
        vim.fn["denops#cache#update"]({ reload = true })
        vim.notify("denops dependencies cached", vim.log.levels.INFO)
      end,
    })

    -- recommended by denops.vim: see :help denops-recommended
    local f = require("kyoh86.lib.func")
    -- Interrupt the process of plugins via <C-c>
    vim.keymap.set({ "n", "i", "c" }, "<c-c>", "<cmd>call denops#interrupt()<cr><c-c>", { remap = false, silent = true })
    -- Restart Denops server
    vim.api.nvim_create_user_command("DenopsRestart", f.bind_all(vim.fn["denops#server#restart"]), {})
    -- Fix Deno module cache issue
    local update = f.bind_all(vim.fn["denops#cache#update"], { reload = true })
    vim.api.nvim_create_user_command("DenopsCacheUpdate", update, {})
    vim.api.nvim_create_user_command("DenopsFixCache", update, {})
  end,
}
return spec
