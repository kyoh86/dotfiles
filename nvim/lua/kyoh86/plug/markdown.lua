---@type LazySpec[]
local spec = {
  {
    "dhruvasagar/vim-table-mode",
    ft = "markdown",
    init = function()
      vim.g.table_mode_disable_mappings = true
      vim.g.table_mode_disable_tableize_mappings = true
    end,
    config = function()
      local group = vim.api.nvim_create_augroup("kyoh86-plug-markdown-table", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        group = group,
        callback = function(ev)
          vim.keymap.set("n", "<leader>mta", "<plug>(table-mode-realign)", { buffer = ev.buf, remap = true, desc = "Markdownテーブルを整列する" })
          vim.keymap.set("n", "<leader>mtt", "<cmd>TableModeToggle<cr>", { buffer = ev.buf, remap = true, desc = "Markdownテーブルモードを切り替える" })
          vim.keymap.set("n", "<leader>mte", "<cmd>TableModeEnable<cr>", { buffer = ev.buf, remap = true, desc = "Markdownテーブルモードを開始" })
          vim.keymap.set("n", "<leader>mtd", "<cmd>TableModeDisable<cr>", { buffer = ev.buf, remap = true, desc = "Markdownテーブルモードを終了" })
        end,
      })
    end,
    keys = {
      "<leader>mtt",
      "<leader>mta",
      "<leader>mte",
      "<leader>mte",
    },
    cmd = {
      "TableModeToggle",
      "TableModeEnable",
      "TableModeRealign",
      "TableModeDisable",
    },
  },
  {
    "previm/previm", -- previous some file-types
    dependencies = { "open-browser.vim" },
    config = function()
      vim.g.previm_enable_realtime = true
      vim.g.previm_code_language_show = true
      vim.g.previm_disable_default_css = true
      vim.g.previm_custom_css_path = vim.fn.stdpath("config") .. "/css/github-markdown.css"
      vim.g.previm_open_cmd = require("kyoh86.glaze.stain.opener")
    end,
  },
}
return spec
