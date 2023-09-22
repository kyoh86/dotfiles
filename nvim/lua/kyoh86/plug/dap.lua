---@type LazySpec
local spec = {
  "mfussenegger/nvim-dap",
  config = function()
    vim.keymap.set("n", "<leader>dc", function()
      require("dap").continue()
    end, { desc = "dap: continue" })
    vim.keymap.set("n", "<leader>dr", function()
      require("dap").repl.toggle()
    end, { desc = "dap: toggle repl" })
    vim.keymap.set("n", "<leader>dK", function()
      require("dap.ui.widgets").hover()
    end, { desc = "dap: show hover" })
    vim.keymap.set("n", "<leader>dt", function()
      require("dap").toggle_breakpoint()
    end, { desc = "dap: toggle breakpoint" })
    vim.keymap.set("n", "<leader>dso", function()
      require("dap").step_over()
    end, { desc = "dap: step-over" })
    vim.keymap.set("n", "<leader>dsi", function()
      require("dap").step_into()
    end, { desc = "dap: step-into" })
    vim.keymap.set("n", "<leader>dl", function()
      require("dap").run_last()
    end, { desc = "dap: run last one" })

    local dap = require("dap")

    dap.configurations.scala = {
      {
        type = "scala",
        request = "launch",
        name = "RunOrTest",
        metals = {
          runType = "runOrTestFile",
        },
      },
      {
        type = "scala",
        request = "launch",
        name = "Test Target",
        metals = {
          runType = "testTarget",
        },
      },
    }
  end,
}
return spec
