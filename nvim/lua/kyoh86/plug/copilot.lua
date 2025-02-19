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
    opts = {
      -- See Configuration section for options
    },
  },
}
return spec
