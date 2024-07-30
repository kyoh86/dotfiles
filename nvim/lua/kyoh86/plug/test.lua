---@type LazySpec
local spec = {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/neotest-jest",
    "fredrikaverpil/neotest-golang",
    "thenbe/neotest-playwright",

    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
  },

  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-golang"), -- Registration

        require("neotest-jest")({
          jestCommand = "npm test --",
          jestConfigFile = "custom.jest.config.ts",
          env = { CI = true },
          cwd = function(path)
            return vim.fn.getcwd()
          end,
        }),

        require("neotest-playwright").adapter({
          options = {
            persist_project_selection = true,
            enable_dynamic_test_discovery = true,
          },
        }),
      },
    })
  end,
  keys = {
    {
      "<leader>tg",
      function()
        require("neotest").run.run_last()
      end,
      silent = true,
      remap = false,
      desc = "最後に実行したテストに移動する",
    },
    {
      "<leader>tn",
      function()
        require("neotest").run.run()
      end,
      silent = true,
      remap = false,
      desc = "カーソル下のテストを実行する",
    },
    {
      "<leader>tf",
      function()
        require("neotest").run.run(vim.fn.expand("%"))
      end,
      silent = true,
      remap = false,
      desc = "現在のファイルのテストを実行する",
    },
    -- TODO: { "<leader>ta", "<cmd>TestSuite<cr>", silent = true, remap = false, desc = "すべてのテストを実行する" },
  },
}
return spec
