---@type LazySpec
local spec = {
  "phelipetls/jsonpath.nvim",
  config = function()
    -- Define mappings for json buffers
    local group = vim.api.nvim_create_augroup("local-with-jsonpath", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "json",
      group = group,
      callback = function()
        vim.keymap.set("n", "<leader>jc", function()
          vim.fn.setreg("+", require("jsonpath").get())
        end, { desc = "copy json path", buffer = true })
        vim.keymap.set("n", "<leader>jd", function()
          print(require("jsonpath").get())
        end, { desc = "echo json-path under the cursor", buffer = true })
      end,
    })
  end,
  ft = "json",
}
return spec
