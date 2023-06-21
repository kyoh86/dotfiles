---@type LazySpec[]
local spec = {
  {
    "lewis6991/gitsigns.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "kyoh86/momiji" },
    config = function()
      local palette = vim.g.momiji_colors
      vim.api.nvim_set_hl(0, "GitSignsAddNr", { fg = palette.grayscale1, bg = palette.lightgreen })
      vim.api.nvim_set_hl(0, "GitSignsChangeNr", { fg = palette.grayscale1, bg = palette.lightcyan })
      vim.api.nvim_set_hl(0, "GitSignsDeleteNr", { fg = palette.grayscale1, bg = palette.lightred })
      local gitsigns = require("gitsigns")
      gitsigns.setup({
        signcolumn = true,
        numhl = false,
        sign_priority = 1,
        on_attach = function(bufnr)
          vim.keymap.set("n", "]g", function()
            if vim.wo.diff then
              return "]g"
            end
            vim.schedule(function()
              gitsigns.next_hunk()
            end)
            return "<Ignore>"
          end, { expr = true, buffer = bufnr, desc = "jump to next git-diff hunk" })

          vim.keymap.set("n", "[g", function()
            if vim.wo.diff then
              return "[g"
            end
            vim.schedule(function()
              gitsigns.prev_hunk()
            end)
            return "<Ignore>"
          end, { expr = true, buffer = bufnr, desc = "jump to next git-diff hunk" })

          vim.keymap.set({ "n", "x" }, "<leader>gs", ":Gitsigns stage_hunk<CR>", { buffer = bufnr, noremap = true })
          vim.keymap.set({ "n", "x" }, "<leader>gr", ":Gitsigns undo_stage_hunk<CR>", { buffer = bufnr, noremap = true })
          vim.keymap.set("n", "<leader>gq", function()
            gitsigns.setqflist("all")
          end, { buffer = bufnr, noremap = true, desc = "Populate the quickfix list with hunks" })
        end,
      })
    end,
    keys = {
      "]g",
      { "<leader>gs", mode = { "n", "x" } },
      { "<leader>gr", mode = { "n", "x" } },
      "<leader>gq",
    },
    event = "BufReadPost",
  },
  {
    "lambdalisue/gin.vim",
    dependencies = { "vim-denops/denops.vim" },
  },
}
return spec
