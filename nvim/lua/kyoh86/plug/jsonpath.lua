---@type LazySpec
local spec = {
  "phelipetls/jsonpath.nvim",
  config = function()
    -- Define mappings for json buffers
    local group = vim.api.nvim_create_augroup("kyoh86-plug-jsonpath", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "json",
      group = group,
      callback = function()
        vim.keymap.set("n", "<leader>yj", function()
          vim.fn.setreg("+", require("jsonpath").get())
        end, { desc = "JSON-pathをYankする", buffer = true })
        vim.keymap.set("n", "<leader>ij", function()
          print(require("jsonpath").get())
        end, { desc = "JSON-pathを表示する", buffer = true })
      end,
    })
  end,
  ft = "json",
}
return spec
