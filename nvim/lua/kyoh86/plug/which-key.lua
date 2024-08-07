---@type LazySpec
local spec = {
  "folke/which-key.nvim",
  config = function()
    local wk = require("which-key")
    wk.add({ "<leader>c", group = "コメント/Caser" })
    wk.add({ "<leader>f", group = "Fuzzy Finder" })
    wk.add({ "<leader>fa", group = "すべてのファイル" })
    wk.add({ "<leader>fd", group = "DocBase" })
    wk.add({ "<leader>fe", group = "絵文字" })
    wk.add({ "<leader>fg", group = "Git/GitHub" })
    wk.add({ "<leader>fm", group = "MMR" })
    wk.add({ "<leader>fp", group = "プロジェクト/リポジトリ" })
    wk.add({ "<leader>fq", group = "Quickfix" })
    wk.add({ "<leader>fv", group = "Vim" })
    wk.add({ "<leader>fz", group = "Zenn.dev" })
    wk.add({ "<leader>d", group = "デバッグ(DAP)" })
    wk.add({ "<leader>g", group = "Git" })
    wk.add({ "<leader>gd", group = "Diff" })
    wk.add({ "<leader>gh", group = "GitHub" })
    wk.add({ "<leader>gc", group = "Conflict" })
    wk.add({ "<leader>i", group = "コンテキスト情報表示" })
    wk.add({ "<leader>l", group = "LSP" })
    wk.add({ "<leader>lc", group = "Call/Code" })
    wk.add({ "<leader>li", group = "コンテキスト情報表示" })
    wk.add({ "<leader>lq", group = "Quickfix" })
    wk.add({ "<leader>m", group = "マークダウン操作" })
    wk.add({ "<leader>mc", group = "チェックボックス操作" })
    wk.add({ "<leader>mt", group = "テーブル操作" })
    wk.add({ "<leader>t", group = "テスト" })
    wk.add({ "<leader>q", group = "Quickfix" })
    wk.add({ "<leader>w", group = "ウインドウ" })
    wk.add({ "<leader>x", group = "外部機能の呼び出し" })
    wk.add({ "<leader>y", group = "Yank" })

    wk.add({ "t", group = "ターミナル" })

    wk.add({ "[x", group = "前のコンフリクトに移動" })
    wk.add({ "]x", group = "後ろのコンフリクトに移動" })

    wk.add({ "sf", group = "関数呼び出し文の加工" })
    wk.add({ "sfa", group = "関数呼び出しで包む" })
    wk.add({ "sfd", group = "関数呼び出しから外に出す" })
    wk.add({ "sa", group = "Sandwich Add" })
    wk.add({ "sc", group = "Sandwich Replace" })
    wk.add({ "sd", group = "Sandwich Delete" })
    wk.add({ "sr", group = "Sandwich Replace" })
  end,
}

return {}
