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

          vim.api.nvim_create_user_command("GitsignsStageSelection", function(ev)
            if ev.range == 0 then
              local line = vim.fn.line(".")
              require("gitsigns").stage_hunk({ line, line })
            elseif ev.range == 1 then
              require("gitsigns").stage_hunk({ ev.line1, ev.line1 })
            elseif ev.range == 2 then
              require("gitsigns").stage_hunk({ ev.line1, ev.line2 })
            end
          end, {
            range = true,
          })
          vim.keymap.set({ "n" }, "<leader>gah", "<cmd>Gitsigns stage_hunk<cr>", { buffer = bufnr, noremap = true, desc = "カーソル位置のHunkをGitに載せる" })
          vim.keymap.set({ "n" }, "<leader>gal", [[<cmd>GitsignsStageSelection<cr>]], { buffer = bufnr, noremap = true, desc = "カーソル行の差分をGitに載せる" })
          vim.keymap.set({ "x" }, "<leader>ga", [[:GitsignsStageSelection<cr>]], { buffer = bufnr, noremap = true, desc = "選択行の差分をGitに載せる" })
          vim.keymap.set({ "n" }, "<leader>gr", "<cmd>Gitsigns undo_stage_hunk<cr>", { buffer = bufnr, noremap = true, desc = "カーソル位置の差分をGitからリセットする" })
          vim.keymap.set({ "x" }, "<leader>gr", ":Gitsigns undo_stage_hunk<cr>", { buffer = bufnr, noremap = true, desc = "洗濯業の差分をGitからリセットする" })
          vim.keymap.set({ "n" }, "<leader>gR", "<cmd>Gitsigns reset_buffer_index<cr>", { buffer = bufnr, noremap = true, desc = "このファイルの差分をUnstageする" })
          vim.keymap.set("n", "<leader>gq", func.bind_all(gitsigns.setqflist, "all"), { buffer = bufnr, noremap = true, desc = "このファイルのGit diffをQuickfixに載せる" })
        end,
      })
    end,
    event = "BufReadPost",
  },
  {
    "lambdalisue/vim-gin",
    dependencies = { "denops.vim" },
    config = function()
      vim.keymap.set("n", "<leader>gdp", "<Plug>(gin-diffput)", { desc = "Put a diff chunk to WORKTREE buffer" })
      vim.keymap.set("n", "<leader>gdg", "<Plug>(gin-diffget)", { desc = "Get a diff chunk from WORKTREE or HEAD buffer (prefer WORKTREE)" })
      vim.keymap.set("n", "<leader>gd>", "<Plug>(gin-diffget-l)", { desc = "Get a diff chunk from HEAD buffer" })
      vim.keymap.set("n", "<leader>gd<", "<Plug>(gin-diffget-r)", { desc = "Get a diff chunk from WORKTREE buffer" })
      vim.keymap.set("n", "<leader>gs", "<cmd>GinStatus<cr>", { desc = "Get a diff chunk from WORKTREE buffer" })

      local group = vim.api.nvim_create_augroup("kyoh86-plug-gin", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "gitcommit", "markdown" },
        group = group,
        callback = function()
          vim.keymap.set("n", "<leader>a", function()
            if vim.b.gin_internal_proxy_waiter then
              return "<cmd>Apply<cr>"
            end
            return "<leader>a"
          end, { expr = true, desc = "Apply a commit message and others" })
          vim.keymap.set("n", "<leader>c", function()
            if vim.b.gin_internal_proxy_waiter then
              return "<cmd>Cancel<cr>"
            end
            return "<leader>c"
          end, { expr = true, desc = "Apply a commit message and others" })
        end,
      })
    end,
  },
}
return spec
