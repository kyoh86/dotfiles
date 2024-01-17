vim.g["test#strategy"] = "neovim"
vim.g["test#neovim#term_position"] = "aboveleft"
vim.g["test#neovim#start_normal"] = 1
vim.g["test#preserve_screen"] = 1
vim.g["test#echo_command"] = true
vim.g["test#lua#busted#executable"] = "vusted"
vim.g["test#runner_commands"] = { "GoTest" }

---@type LazySpec
local spec = {
  "vim-test/vim-test",
  dependencies = { "vim-dispatch" },
  cmd = {
    "TestVisit",
    "TestNearest",
    "TestNearest",
    "TestFile",
    "TestSuite",
    "TestLast",
    "GoTest",
  },
  keys = {
    { "<leader>tg", "<cmd>TestVisit<cr>", silent = true, remap = false, desc = "最後に実行したテストに移動する" },
    { "<leader>tn", "<cmd>TestNearest<cr>", silent = true, remap = false, desc = "カーソル下のテストを実行する" },
    { "<leader>tf", "<cmd>TestFile<cr>", silent = true, remap = false, desc = "現在のファイルのテストを実行する" },
    { "<leader>ta", "<cmd>TestSuite<cr>", silent = true, remap = false, desc = "すべてのテストを実行する" },
    { "<leader>tt", "<cmd>TestLast<cr>", silent = true, remap = false, desc = "最後に実行したテストを再実行する" },
  },
  config = function()
    local custom_alternate_file = function(cmd)
      local file = vim.api.nvim_buf_get_name(0)
      if file:match("_test.lua$") then
        return file:gsub("_test.lua$", ".lua")
      elseif file:match(".spec.lua$") then
        return file:gsub(".spec.lua$", ".lua")
      elseif file:match(".test.lua$") then
        return file:gsub(".test.lua$", ".lua")
      elseif file:match("_spec.lua$") then
        return file:gsub("_spec.lua$", ".lua")
      elseif file:match(".lua$") then
        return file:gsub(".lua$", "_test.lua")
      end
    end

    vim.g["test#custom_alternate_file"] = custom_alternate_file
    vim.g["test#javascript#denotest#executable"] = "NO_COLOR=1 deno test"

    -- register custom runners
    vim.g["test#custom_runners"] = { javascript = { "denopstest" } }
  end,
}
return spec
