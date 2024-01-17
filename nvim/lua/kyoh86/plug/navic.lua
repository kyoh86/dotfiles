---@type LazySpec
local spec = {
  "SmiteshP/nvim-navic",
  dependencies = {"nvim-lspconfig"},
  setup = function(use)
    use({
      "SmiteshP/nvim-navic",
      config = function()
        require("nvim-navic").setup({
          on_attach = function(client, bufnr)
            require("nvim-lspconfig").on_attach(client, bufnr)
          end,
        })
      end,
    })
  end,
}
return spec
