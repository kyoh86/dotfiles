---@type LazySpec
local spec = {
  "github/copilot.vim",
  init = function()
    vim.g.copilot_no_maps = true
    vim.keymap.set("i", "<c-x><c-c>", function()
      vim.fn["copilot#Accept"]("")
    end, {
      expr = true,
    })
    vim.g.copilot_no_tab_map = true
    vim.g.copilot_filetypes = {
      ["ddu-ff-filter"] = false,
    }
  end,
}
return spec
