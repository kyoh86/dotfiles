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
      local au = require("kyoh86.lib.autocmd")
      au.group("kyoh86.plug.markdown.table", true):hook("FileType", {
        pattern = "markdown",
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
    config = function()
      vim.g.previm_enable_realtime = true
      vim.g.previm_code_language_show = true
      vim.g.previm_disable_default_css = true
      vim.g.previm_custom_css_path = vim.fn.stdpath("config") .. "/css/github-markdown.css"
      local wsl_distro = os.getenv("WSL_DISTRO_NAME")
      if wsl_distro ~= nil and wsl_distro ~= "" then
        vim.g.previm_wsl_mode = true
        vim.g.previm_open_cmd = "/mnt/c/Windows/explorer.exe"
      else
        local glaze = require("kyoh86.lib.glaze")
        glaze.get_async("opener", function(opener)
          vim.g.previm_open_cmd = opener
        end)
      end
    end,
  },
}
return spec
