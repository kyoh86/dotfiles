local function register_lsp_servers()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  }

  local function register(name, config, skip_mason)
    config.capabilities = capabilities
    if not skip_mason then
      table.insert(lsp_server_list, name)
    end
    lsp_config_table[name] = config
  end

  register("angularls", {})
  register("ansiblels", {})
  register("astro", {})
  register("bashls", {})
  register("biome", {})
  register("cssls", {})
  register("cssmodules_ls", {})
  register("denols", require("kyoh86.plug.lsp.server.denols"), true) -- uses global deno, so it should not be installed by Mason
  register("dockerls", {})
  register("efm", require("kyoh86.plug.lsp.server.efm"))
  register("eslint", {})
  register("gopls", require("kyoh86.plug.lsp.server.gopls"))
  register("html", {})
  register("jsonls", require("kyoh86.plug.lsp.server.jsonls"))
  register("jqls", {})
  register("lemminx", {}) -- XML
  register("lua_ls", require("kyoh86.plug.lsp.server.luals"))
  register("metals", {}, true) -- Scala (metals): without installation with mason.nvim
  register("prismals", {}) -- Prisma (TypeScript DB ORM)
  register("pylsp", {
    settings = {
      pylsp = {
        plugins = {
          pycodestyle = { enabled = true, ignore = { "E501" } },
          pydocstyle = { enabled = false },
          pylint = { enabled = false },
          flake8 = { enabled = false },
          mypy = { enabled = false },
          isort = { enabled = false },
          yapf = { enabled = false },
          black = { enabled = true },
        },
      },
    },
  })
  register("pyright", {})
  register("rust_analyzer", require("kyoh86.plug.lsp.server.rust"), true)
  register("sqlls", {})
  register("stylelint_lsp", {})
  register("svelte", {})
  register("taplo", {}) -- TOML
  register("terraformls", {})
  register("tflint", {})
  register("vimls", {})
  register("vtsls", require("kyoh86.plug.lsp.server.vtsls"))
  register("yamlls", {
    settings = {
      yaml = {
        schemaStore = { enable = true },
        keyOrdering = false,
      },
    },
  })
end
return {
  register = register_lsp_servers
}
