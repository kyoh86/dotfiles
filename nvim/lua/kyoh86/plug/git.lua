local func = require("kyoh86.lib.func")
---@type LazySpec[]
local spec = {
  {
    "lewis6991/gitsigns.nvim",
    dependencies = { "plenary.nvim", "momiji" },
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
            vim.schedule(func.bind_all(gitsigns.next_hunk))
            return "<Ignore>"
          end, { expr = true, buffer = bufnr, desc = "次のgit diffに移動する" })

          vim.keymap.set("n", "[g", function()
            if vim.wo.diff then
              return "[g"
            end
            vim.schedule(func.bind_all(gitsigns.prev_hunk))
            return "<Ignore>"
          end, { expr = true, buffer = bufnr, desc = "前のgit diffに移動する" })

          vim.keymap.set({ "n", "x" }, "<leader>gs", ":Gitsigns stage_hunk<CR>", { buffer = bufnr, noremap = true, desc = "カーソル位置の差分をGitに載せる" })
          vim.keymap.set({ "n", "x" }, "<leader>gr", ":Gitsigns undo_stage_hunk<CR>", { buffer = bufnr, noremap = true, desc = "カーソル位置の差分をGitからリセットする" })
          vim.keymap.set("n", "<leader>gq", func.bind_all(gitsigns.setqflist, "all"), { buffer = bufnr, noremap = true, desc = "このファイルのGit diffをQuickfixに載せる" })
        end,
      })
    end,
    event = "BufReadPost",
  },
  {
    "lambdalisue/gin.vim",
    dependencies = { "denops.vim" },
    config = function()
      vim.keymap.set("n", "<leader>gdp", "<Plug>(gin-diffput)", { desc = "Put a diff chunk to WORKTREE buffer" })
      vim.keymap.set("n", "<leader>gdg", "<Plug>(gin-diffget)", { desc = "Get a diff chunk from WORKTREE or HEAD buffer (prefer WORKTREE)" })
      vim.keymap.set("n", "<leader>gd>", "<Plug>(gin-diffget-l)", { desc = "Get a diff chunk from HEAD buffer" })
      vim.keymap.set("n", "<leader>gd<", "<Plug>(gin-diffget-r)", { desc = "Get a diff chunk from WORKTREE buffer" })
    end,
  },
}
return spec
