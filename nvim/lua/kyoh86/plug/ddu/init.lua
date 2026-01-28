---@type LazySpec[]
local spec = {
  {
    "Shougo/ddu.vim",
    config = function()
      vim.fn["ddu#custom#patch_global"]({
        sourceOptions = {
          _ = {
            ignoreCase = true,
          },
        },
      })

      local glaze = require("kyoh86.lib.glaze")
      glaze.get_async("opener", function(opener)
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

      helper.setup("codex-session", {
        sources = { {
          name = "codex_session",
          options = {
            columns = {
              "codex_session_time",
              "codex_session_name",
              "codex_session_path",
            },
          },
        } },
        kindOptions = {
          codex_session = {
            defaultAction = "resume",
          },
        },
        uiParams = {
          ff = {
            startAutoAction = true,
          },
        },
      }, {
        start = {
          key = "<leader>fcs",
          desc = "Codex セッション",
        },
        filelike = true,
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
