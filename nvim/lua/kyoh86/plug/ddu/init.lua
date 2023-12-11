local func = require("kyoh86.lib.func")
---@type LazySpec[]
local spec = {
  {
    "Shougo/ddu.vim",
    config = function(plugin)
      local group = vim.api.nvim_create_augroup("kyoh86-plug-ddu-static-import", { clear = true })
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = { "LazyUpdate" },
        callback = function()
          vim.fn["ddu#set_static_import_path"]()
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = { "LazyUpdatePre" },
        callback = function()
          local cmd = string.format("git -C %q restore denops/ddu/_mods.js", plugin.dir)
          vim.fn.system(cmd)
        end,
      })
      vim.fn["ddu#custom#patch_global"]({
        sourceOptions = {
          _ = {
            ignoreCase = true,
          },
        },
      })
    end,
    dependencies = { "denops.vim" },
  },
  { import = "kyoh86.plug.ddu.source" },
  { import = "kyoh86.plug.ddu.filter" },
  { import = "kyoh86.plug.ddu.kind" },
  { import = "kyoh86.plug.ddu.ui" },
}
return spec
