if vim.opt_local.buftype:get() ~= "help" then
  --- 編集中ヘルプの見た目変更

  --- インデント設定
  local indent_size = 8
  vim.opt_local.tabstop = indent_size
  vim.opt_local.shiftwidth = indent_size
  vim.opt_local.expandtab = false

  local text_width = 78
  vim.opt_local.colorcolumn = { text_width + 2 }
  vim.opt_local.textwidth = text_width

  vim.api.nvim_set_hl(0, "helpIgnore", { link = "PreProc" })
  vim.api.nvim_set_hl(0, "helpBar", { link = "PreProc" })
  vim.api.nvim_set_hl(0, "helpStar", { link = "PreProc" })
  vim.api.nvim_set_hl(0, "helpBacktick", { link = "PreProc" })
  if vim.fn.has("conceal") == 1 then
    vim.opt_local.conceallevel = 0
  end

  vim.g.autofmt_allow_over_tw = 1
  vim.opt_local.formatoptions:append({ "m", "B" })
  vim.opt_local.smartindent = true

  -- 便利機能
  vim.keymap.set("n", "<leader>>", function()
    local value = vim.trim(vim.api.nvim_get_current_line())
    local words = {}
    for c in vim.gsplit(value, "%s+", { trimempty = true }) do
      table.insert(words, c)
    end
    if #words == 1 then
      vim.api.nvim_set_current_line(string.rep(" ", text_width - #value) .. value)
    elseif #words == 2 then
      vim.api.nvim_set_current_line(words[1] .. string.rep(" ", text_width - #words[1] - #words[2]) .. words[2])
    else
      vim.notify("unsupported line: there're more than two words", vim.log.levels.WARN)
    end
  end, { desc = "align right" })

  local sep = string.rep("=", text_width)
  vim.keymap.set("n", "<leader>==", function()
    vim.api.nvim_put({ sep }, "l", true, true)
  end, { desc = "put horizontal line" })

  -- Template
  local prof = vim.fn.wordcount()
  if prof.bytes == 0 then
    local name = vim.fn.expand("%:p:h:h:t:s?^vim-??:s?\\.vim$??:s?\\.nvim$??")
    vim.api.nvim_put({
      name .. ".txt                          (description of the plugin)",
      "",
      "Author: kyoh86 <me@kyoh86.dev>",
      "License: MIT License",
      "",
      "",
      sep,
      "CONTENTS" .. string.rep(" ", 53) .. "*" .. name .. "-contents*",
      "",
      "Introduction" .. string.rep(" ", 32) .. "|" .. name .. "-introdution|",
      "Function" .. string.rep(" ", 36) .. "|" .. name .. "-function|",
      "",
      sep,
      "FUNCTION" .. string.rep(" ", 53) .. "*" .. name .. "-function*",
      "",
      "",
      sep,
      "vim:tw=78:ts=8:sw=8:ft=help:norl:noet:fen:",
    }, "l", false, false)
  end
end
