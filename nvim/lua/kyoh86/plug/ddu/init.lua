---@type LazySpec[]
local spec = {
  {
    "Shougo/ddu.vim",
    config = function()
      local group = vim.api.nvim_create_augroup("kyoh86-plug-ddu-static-import", { clear = true })
      vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = { "LazyInstall", "LazyUpdate", "LazyClean", "LazySync" },
        callback = require("kyoh86.lib.func").vind_all(vim.fn["ddu#set_static_import_path"]),
      })
      vim.fn["ddu#custom#patch_global"]({
        sourceOptions = {
          _ = {
            ignoreCase = true,
          },
        },
      })

      local glaze = require("kyoh86.lib.glaze")
      glaze.get("opener", function(opener)
        vim.fn["ddu#custom#patch_global"]({
          actionParams = {
            browse = { opener = opener },
          },
        })
      end)

      -- Dotfiles内で定義したSourceなどの設定（※ddu.vim, denops.vimの読み込みに依存するため、この位置）
      local helper = require("kyoh86.plug.ddu.helper")

      helper.setup("aws-profile", {
        sources = { {
          name = "aws_profile",
          options = {
            defaultAction = "setenv",
          },
        } },
        uiParams = {
          ff = {
            startAutoAction = false,
          },
        },
      }, {
        start = {
          key = "<leader>fap",
          desc = "AWS プロファイルの切り替え",
        },
      })
    end,
    build = "git update-index --skip-worktree denops/ddu/_mods.js",
    dependencies = { "denops.vim" },
  },
  { import = "kyoh86.plug.ddu.source" },
  { import = "kyoh86.plug.ddu.filter" },
  { import = "kyoh86.plug.ddu.kind" },
  { import = "kyoh86.plug.ddu.ui" },
}
return spec
