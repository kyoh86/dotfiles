--- 環境変数設定
local envar = require("kyoh86.lib.envar")

-- Neovim server name
envar.set_tmux("NVIM_SERVER_NAME", vim.v.servername)

-- browser
local glaze = require("kyoh86.lib.glaze")
glaze.get_async("opener", function(opener)
  envar.set_tmux("BROWSER", opener)
end)
