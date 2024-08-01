---@type LazySpec
local spec = {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup({
      sync_install = false,
      ignore_install = { "all" },
      ensure_installed = { "go", "gomod", "gosum", "gotmpl", "gowork", "typescript" },
      auto_install = true,

      highlight = {
        enable = false,
      },
      modules = {},
    })
    local group = vim.api.nvim_create_augroup("kyoh86-plug-treesitter-auto-tsupdate", { clear = true })
    vim.api.nvim_create_autocmd("User", {
      group = group,
      pattern = { "LazyInstall", "LazyUpdate" },
      callback = function()
        vim.cmd["TSUpdate"]()
      end,
    })
  end,
}
return spec
