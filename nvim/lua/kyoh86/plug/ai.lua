---@type LazySpec[]
local specs = {
  {
    "olimorris/codecompanion.nvim",
    opts = {
      extensions = {
        mcphub = {
          callback = "mcphub.extensions.codecompanion",
          opts = {
            make_vars = true, -- Convert resources to #variables
            show_result_in_chat = true, -- Show mcp tool results in chat
            make_slash_commands = true, -- Add prompts as /slash commands
          },
        },
      },
      strategies = {
        chat = {
          keymaps = {
            completion = {
              modes = {
                i = "<C-Space>",
              },
            },
          },
        },
      },
    },
    config = function(_, opts)
      require("codecompanion").setup(opts)
      vim.keymap.set({ "ca" }, "cc", "CodeCompanion")
      vim.keymap.set({ "ca" }, "ccc", "CodeCompanionChat")
    end,
    dependencies = {
      "plenary.nvim",
      "nvim-treesitter",
      "nvim-treesitter-textobjects",
      "mcphub.nvim",
    },
  },
  {
    "ravitemer/mcphub.nvim",
    build = "bundled_build.lua",
    opts = {
      use_bundled_binary = true,
    },
  },
}
return specs
