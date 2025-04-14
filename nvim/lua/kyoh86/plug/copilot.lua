---@type LazySpec
local spec = {
  {
    "github/copilot.vim",
    init = function()
      vim.g.copilot_no_maps = true
      vim.keymap.set("i", "<c-x><c-a>", 'copilot#Accept("\\<c-x>\\<c-a>")', {
        expr = true,
        replace_keycodes = false,
      })
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_filetypes = {
        ["ddu-ff-filter"] = false,
      }
    end,
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "github/copilot.vim" },
      { "plenary.nvim" }, -- for curl, log and async functions
    },
    build = "make tiktoken",
    config=function()
      require("CopilotChat").setup({ })
      vim.api.nvim_create_autocmd('BufEnter', {
        pattern = 'copilot-*',
        callback = function()
          -- Set buffer-local options
          vim.opt_local.relativenumber = false
          vim.opt_local.conceallevel = 0
        end
      })
    end,
  },
}
return spec
