---@type LazySpec
local spec = {
  "folke/which-key.nvim",
  config = function()
    local wk = require("which-key")
    wk.setup({
      triggers = { "<leader>" },
      triggers_nowait = {
        "<leader>",
      },
    })
    wk.register({
      f = {
        name = "Fuzzy Finder",
      },
      ["\\"] = {
        name = "設定へのショートカット類",
      },
      d = {
        name = "デバッグ(DAP)",
      },
      g = {
        name = "Git",
        d = {
          name = "Diff",
        },
      },
      i = {
        name = "コンテキスト情報表示",
      },
      l = {
        name = "LSP",
        i = {
          name = "コンテキスト情報表示",
        },
        q = {
          name = "Quickfix",
        },
      },
      t = {
        name = "テスト/翻訳",
      },
      q = {
        name = "Quickfix",
      },
      w = {
        name = "ウィンドウ",
      },
      x = {
        name = "外部機能の呼び出し",
      },
      y = {
        name = "Yank",
      },
    }, {
      prefix = "<leader>",
    })
    wk.register({
      t = "ターミナル",
    })
  end,
}
return spec
