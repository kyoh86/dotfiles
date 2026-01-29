---@type LazySpec
local spec = {
  "phelipetls/jsonpath.nvim",
  config = function()
    -- Define mappings for json buffers
    local au = require("kyoh86.lib.autocmd")
    au.group("kyoh86.plug.jsonpath", true):hook("FileType", {
      pattern = "json",
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
