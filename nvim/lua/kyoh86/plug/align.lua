---@type LazySpec
local spec = {
  "Vonr/align.nvim",
  config = function()
    --
    vim.keymap.set("x", "<leader>ac", function()
      require("align").align_to_char(1, true)
    end, { desc = "aligns to 1 character, looking left" })
    vim.keymap.set("x", "<leader>as", function()
      require("align").align_to_string(false, true, true)
    end, { desc = "aligns to a string, looking left and with previews" })
    vim.keymap.set("x", "<leader>ar", function()
      require("align").align_to_string(true, true, true)
    end, { desc = "aligns to a Lua pattern, looking left and with previews" })

    vim.keymap.set("n", "gac", function()
      local a = require("align")
      a.operator(a.align_to_char, { length = 1, reverse = true })
    end, { desc = "aling a textobj to 1 character, looking left" })
    vim.keymap.set("n", "<leader>as", function()
      local a = require("align")
      a.operator(a.align_to_string, { is_pattern = false, reverse = true, preview = true })
    end, { desc = "align a textobj to a string, looking left and with previews" })
    vim.keymap.set("n", "<leader>ar", function()
      local a = require("align")
      a.operator(a.align_to_string, { is_pattern = true, reverse = true, preview = true })
    end, { desc = "align a textobj to a Lua pattern, looking left and with previews" })
  end,
}
return spec
