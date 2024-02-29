local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "shun/ddu-source-buffer",
  dependencies = { "ddu.vim", "ddu-kind-file" },
  config = function()
    local custom_bdelete = function(args)
      for _, file in pairs(args.items) do
        local bufnr = vim.tbl_get(file, "action", "bufNr")
        if bufnr ~= nil then
          vim.cmd.bdelete({
            args = { bufnr }, --[[bang = true]]
          })
        end
      end
      return 0
    end

    vim.fn["ddu#custom#action"]("kind", "file", "custom:bdelete", custom_bdelete)
    helper.setup("buffer", { sources = { { name = "buffer", options = { matchers = { "buffer_quickfix", "matcher_fzf" }, converters = { "buffer_terminal_title" } } } } }, {
      start = {
        key = "<leader>fb",
        desc = "バッファ",
      },
      filelike = true,
      localmap = {
        ["<leader>d"] = { action = "itemAction", params = { name = "custom:bdelete" } },
      },
    })
  end,
}
return spec
