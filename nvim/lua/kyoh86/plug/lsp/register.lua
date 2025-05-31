--- LSPサーバー毎の設定管理
return function()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  }
  vim.lsp.config("*", { capabilities = capabilities })

  vim.lsp.enable("ansiblels")
  vim.lsp.enable("astro")
  vim.lsp.enable("bashls")
  vim.lsp.enable("cssls") -- vscode-langservers-extracted
  vim.lsp.enable("denols") -- ref: nvim/lsp/denols.lua; uses global deno, so it should not be installed by Mason
  vim.lsp.enable("dockerls")
  vim.lsp.enable("efm") -- ref: nvim/lsp/efm.lua;
  vim.lsp.enable("eslint")
  vim.lsp.enable("gopls") -- ref: nvim/lsp/gopls.lua; uses global gopls, so it should not be installed by Mason
  vim.lsp.enable("html") -- vscode-langservers-extracted
  vim.lsp.enable("jsonls") -- ref: nvim/lsp/jsonls.lua; vscode-langservers-extracted
  vim.lsp.enable("jqls")
  vim.lsp.enable("lua_ls") -- ref: nvim/lsp/lua_ls.lua;
  vim.lsp.enable("metals") -- Scala (metals): without installation with mason.nvim
  vim.lsp.enable("prismals") -- Prisma (TypeScript DB ORM)
  vim.lsp.enable("rust_analyzer") -- ref: nvim/lsp/rust_analyzer.lua;
  vim.lsp.enable("sqls")
  vim.lsp.enable("stylelint_lsp")
  vim.lsp.enable("svelte")
  -- vim.lsp.enable("taplo") -- TOML
  vim.lsp.enable("terraformls")
  vim.lsp.enable("tombi")-- TOML
  vim.lsp.enable("vimls")
  vim.lsp.enable("vtsls") -- ref: nvim/lsp/vtsls.lua;
  vim.lsp.enable("yamlls") -- ref: nvim/lsp/yamlls.lua;
end
