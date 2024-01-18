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
      ["\\"] = {
        name = "設定へのショートカット類",
      },
      c = {
        name = "コメント/Caser",
      },
      f = {
        name = "Fuzzy Finder",
        a = {
          name = "すべてのファイル",
        },
        e = {
          name = "絵文字",
        },
        g = {
          name = "Git/GitHub",
        },
        m = {
          name = "MMR",
        },
        p = {
          name = "プロジェクト/リポジトリ",
        },
        q = {
          name = "Quickfix",
        },
        v = {
          name = "Vim",
        },
        z = {
          name = "Zenn.dev",
        },
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
        c = {
          "Call/Code",
        },
        i = {
          name = "コンテキスト情報表示",
        },
        q = {
          name = "Quickfix",
        },
      },
      m = {
        name = "マークダウン操作",
        c = {
          name = "チェックボックス操作",
        },
        t = {
          name = "テーブル操作",
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
