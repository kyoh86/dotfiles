---@type LazySpec
local spec = {
  "stevearc/aerial.nvim",
  opts = {
    on_attach = function(bufnr)
      -- Jump forwards/backwards with '{' and '}'
      vim.keymap.set("n", "<leader>{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
      vim.keymap.set("n", "<leader>}", "<cmd>AerialNext<CR>", { buffer = bufnr })
    end,
    layout = {
      default_direction = "right",
    },
    open_automatic = function(bufnr)
      return vim.bo[bufnr].buftype == "help"
    end,
  },
  -- Optional dependencies
  dependencies = {
    "nvim-treesitter",
    "nvim-web-devicons",
  },
}
return spec
