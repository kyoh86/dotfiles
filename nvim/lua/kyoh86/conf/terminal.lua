--- ターミナル関係の設定
vim.o.termguicolors = true

local au = require("kyoh86.lib.autocmd")
local group = au.group("kyoh86.conf.terminal", true)
group:hook("TermOpen", {
  pattern = "term://*",
  callback = function()
    -- 行番号を表示しない
    vim.opt_local.number = false
    vim.opt_local.scrollback = 100000
    vim.opt_local.relativenumber = false
    local buf = vim.api.nvim_get_current_buf()
    -- ノーマルモード、ヴィジュアルモードの<Up>/<Down>で一つ前/後のプロンプトに戻る
    vim.keymap.set("n", "<up>", "[[", { buffer = buf, desc = "Jump [count] shell prompts backward", remap = true })
    vim.keymap.set("n", "<down>", "]]", { buffer = buf, desc = "Jump [count] shell prompts forward", remap = true })
  end,
})

-- OSC 133対応のターミナルプロンプトマーカー

local ns = vim.api.nvim_create_namespace("terminal_prompt_markers")
group:hook("TermRequest", {
  callback = function(args)
    if string.match(args.data.sequence, "^\027]133;A") then
      local lnum = args.data.cursor[1]
      vim.api.nvim_buf_set_extmark(args.buf, ns, lnum - 1, 0, {
        -- Replace with sign text and highlight group of choice
        sign_text = "▶",
        sign_hl_group = "SpecialChar",
      })
    end
  end,
})

-- Enable signcolumn in terminal buffers
group:hook("TermOpen", {
  command = "setlocal signcolumn=auto",
})
