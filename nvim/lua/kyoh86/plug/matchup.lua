---@type LazySpec
local spec = {
  "andymass/vim-matchup",
  config = function()
    -- may set any options here
    vim.g.matchup_matchparen_offscreen = {}

    -- NOTE: Cursorは基本的にTUIモードのNeovimだと効いてない (:help 'guicursor')
    --
    -- MatchParenで1文字だけ色を変えると、カーソル下だけ色が変わるもんだから、
    -- ターミナルエミュレータが変に気を利かせて「カーソルが目立たなくなってる」と判断してカーソルの色を変えてしまう（例: Windows Terminal）
    --
    -- ただ、MatchParenで派手な色に変えてると、カーソルの色を「派手な色の中で逆に目立つ色＝地味な色」に変えられてしまい、
    -- 周りは地味な色のままなのでカーソルが目立たなくなる。なのでMatchParenCurは究極の地味な色＝Normalにしておくのが丸い
    vim.cmd(string.format([[highlight link MatchParenCur Normal]]))
  end,
  event = "VeryLazy",
}
return spec
