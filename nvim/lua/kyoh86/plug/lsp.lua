--- LSPで表示されるDiagnosticsのフォーマット
local function format_diagnostics(diag)
  if diag.code then
    return string.format("[%s](%s): %s", diag.source, diag.code, diag.message)
  else
    return string.format("[%s]: %s", diag.source, diag.message)
  end
end

local diagnosis_config = {
  format = format_diagnostics,
  header = {},
  scope = "cursor",
}

--- Globalな設定
local lsp_server_list = {}
local lsp_config_table = {}
local function setup_lsp_global()
  kyoh86.ensure("mason", function(m)
    m.setup({
      log_level = vim.log.levels.DEBUG,
    })
  end)
  kyoh86.ensure("mason-lspconfig", function(m)
    m.setup({
      ensure_installed = lsp_server_list,
    })
  end)
  kyoh86.ensure("lsp-format", function(m)
    m.setup()
  end)

  -- 随時表示されるDiagnosticsのフォーマット設定
  vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
    update_in_insert = false,
    float = diagnosis_config,
    virtual_text = diagnosis_config,
  })

  -- hoverの表示に表示元(source)を表示
  vim.api.nvim_create_autocmd("LspAttach", {
    once = true,
    callback = function()
      vim.lsp.handlers["textDocument/hover"] = function(_, results, ctx, config)
        local client = vim.lsp.get_client_by_id(ctx.client_id)
        vim.lsp.handlers.hover(
          _,
          results,
          ctx,
          vim.tbl_deep_extend("force", config or {}, {
            border = "single",
            title = " " .. client.name .. " ",
          })
        )
      end
    end,
  })

  -- サーバー毎の設定を反映させる
  -- NOTE: mason, mason-lspconfig, lsp-formatより後にsetupを呼び出す必要がある
  for name, config in pairs(lsp_config_table) do
    kyoh86.ensure("lspconfig", function(m)
      m[name].setup(config)
    end)
  end

  -- highlightを設定する
  kyoh86.ensure("momiji", function(m)
    -- local m = require("momiji")
    vim.api.nvim_set_hl(0, "LspInlayHint", {
      fg = m.colors.lightgreen,
    })
  end)
end

--- Attach時の設定: Keymapの設定
local function setup_lsp_keymap()
  local setmap = function(modes, lhr, rhr, desc)
    vim.keymap.set(modes, lhr, rhr, { remap = false, silent = true, desc = desc })
  end
  -- show / edit actions
  setmap("n", "<leader>li", function()
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.b[bufnr].kyoh86_plug_lsp_inlay_hint_enabled == true then
      vim.lsp.buf.inlay_hint(bufnr, nil)
    end
  end, "displays inlay hints")
  setmap("n", "<leader>lh", vim.lsp.buf.hover, "displays hover information about the symbol under the cursor in a floating window")
  setmap("n", "<leader>ls", vim.lsp.buf.signature_help, "displays signature information about the symbol under the cursor in a floating window")
  setmap("n", "<leader>lr", vim.lsp.buf.rename, "renames all references to the symbol under the cursor")
  setmap("n", "]l", vim.diagnostic.goto_next, "move to the next diagnostic")
  setmap("n", "[l", vim.diagnostic.goto_prev, "move to the previous diagnostic in the current buffer")

  local function range_from_selection(mode)
    -- workaround for https://github.com/neovim/neovim/issues/22629
    local start = vim.fn.getpos("v")
    local end_ = vim.fn.getpos(".")
    local start_row = start[2]
    local start_col = start[3]
    local end_row = end_[2]
    local end_col = end_[3]

    if start_row == end_row and end_col < start_col then
      end_col, start_col = start_col, end_col
    elseif end_row < start_row then
      start_row, end_row = end_row, start_row
      start_col, end_col = end_col, start_col
    end
    if mode == "V" then
      -- select whole line in the selection (in linewise-visual mode)
      start_col = 1
      local lines = vim.api.nvim_buf_get_lines(0, end_row - 1, end_row, true)
      end_col = #lines[1]
    end
    return {
      start = { start_row, start_col - 1 },
      ["end"] = { end_row, end_col - 1 },
    }
  end
  setmap({ "n", "v" }, "<leader>lca", function()
    local range = range_from_selection(vim.api.nvim_get_mode().mode)
    vim.lsp.buf.code_action({ range = range })
  end, "selects a code action available at the current cursor position")

  -- listup actions
  setmap("n", "<leader>llr", vim.lsp.buf.references, "lists all the references to the symbol under the cursor in the quickfix window")
  setmap("n", "<leader>lls", vim.lsp.buf.document_symbol, "lists all symbols in the current buffer in the quickfix window")
  setmap("n", "<leader>llS", vim.lsp.buf.workspace_symbol, "lists all symbols in the current workspace in the quickfix window")
  setmap("n", "<leader>llc", vim.lsp.buf.incoming_calls, "lists all the call sites of the symbol under the cursor in the quickfix window")
  setmap("n", "<leader>llC", vim.lsp.buf.outgoing_calls, "lists all the items that are called by the symbol under the cursor in the quickfix window")
  setmap("n", "<leader>lld", vim.diagnostic.setqflist, "add all diagnostics to the quickfix list")

  -- show diagnostics
  setmap("n", "<leader>lll", function()
    vim.diagnostic.open_float(diagnosis_config)
  end, "show diagnostics in a floating window")
end

--- Attach時の設定: LSPによるImport文の再編とフォーマットの適用
local function attach_lsp(client, bufnr)
  local organize_import = function() end
  local actions = vim.tbl_get(client.server_capabilities, "codeActionProvider", "codeActionKinds")
  if actions ~= nil and vim.tbl_contains(actions, "source.organizeImports") then
    organize_import = function()
      vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
    end
  elseif client.name == "pyright" then
    organize_import = function()
      local params = {
        command = "pyright.organizeimports",
        arguments = { vim.uri_from_bufnr(bufnr) },
      }
      vim.lsp.buf.execute_command(params)
    end
  end

  local group = vim.api.nvim_create_augroup("kyoh86-plug-lsp-format", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = group,
    buffer = bufnr,
    callback = function()
      organize_import()
      kyoh86.ensure("lsp-format", function(m)
        m.format({ fargs = { "sync" } })
      end)
    end,
  })

  client.server_capabilities.semanticTokensProvider = nil
end

--- LSP Context Locationを表示する nvim-navic のアタッチ
local function attach_navic(client, bufnr)
  kyoh86.ensure("nvim-navic", function(navic)
    if client.server_capabilities.documentSymbolProvider then
      navic.attach(client, bufnr)
    end
  end)
end

--- Attach時の設定: 特定のBuffer名と特定のClient名の組み合わせで、LSP Clientを無効化する
--- バッファ名のパターンをPlain textとして扱いたい（パターンではなくLiteral matchとする）場合はplain = trueを指定する
local disabled_clients = {
  eslint = { {
    name = "upmind-inc/upmind-server",
    plain = true,
  } },
}

local function disable_lsp(client, bufnr)
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local lsp_local_disable = disabled_clients[client.name]
  if lsp_local_disable then
    for _, v in pairs(lsp_local_disable) do
      if string.find(bufname, v.name, 1, v.plain) then
        client.stop()
        break
      end
    end
  end
end

--- Attach時の設定

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    kyoh86.ensure("lsp-format", function(m)
      m.on_attach(client)
    end)
    if client.server_capabilities.inlayHintProvider then
      vim.b.kyoh86_plug_lsp_inlay_hint_enabled = true
    end
    attach_lsp(client, bufnr)
    attach_navic(client, bufnr)
    disable_lsp(client, bufnr)
  end,
})

--- LSPサーバー毎の設定管理
local function register_lsp_servers()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  kyoh86.ensure("cmp_nvim_lsp", function(m)
    capabilities = m.default_capabilities(capabilities)
  end)
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
  register("bashls", {})
  register("cssls", {})
  register("cssmodules_ls", {})
  register("dockerls", {})
  register("golangci_lint_ls", {
    init_options = {
      command = {
        "golangci-lint",
        "run",
        "--enable",
        "exportloopref",
        "--out-format",
        "json",
        "--issues-exit-code=1",
      },
    },
  })
  register("gopls", {
    init_options = {
      usePlaceholders = true,
      semanticTokens = true,
      staticcheck = true,
      experimentalPostfixCompletions = true,
      directoryFilters = {
        "-node_modules",
      },
      analyses = {
        nilness = true,
        unusedparams = true,
        unusedwrite = true,
        fieldalignment = true,
      },
      codelenses = {
        gc_details = true,
        test = true,
        tidy = true,
      },
      hints = {
        assignVariableTypes = true,
        compositeLiteralTypes = true,
        constantValues = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
    },
  })
  register("graphql", {})
  register("html", {})
  register("jsonls", {
    schemas = require("schemastore").json.schemas(),
  })
  register("lemminx", {}) -- XML
  register("metals", {}, true) -- Scala (metals): without installation with mason.nvim
  register("pylsp", {})
  register("pyright", {})
  register("rust_analyzer", {})
  register("sqlls", {})
  register("stylelint_lsp", {})

  register("lua_ls", {
    settings = {
      Lua = {
        hint = {
          -- Enable inlay hints
          enable = true,
        },
        runtime = {
          -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
          version = "LuaJIT",
        },
        workspace = {
          -- Make the server aware of Neovim runtime files
          library = vim.api.nvim_get_runtime_file("", true),
          checkThirdParty = false,
        },
        completion = {
          callSnippet = "Replace",
        },
        -- Do not send telemetry data containing a randomized but unique identifier
        telemetry = {
          enable = false,
        },
        format = {
          enable = false,
        },
      },
    },
  })
  register("taplo", {}) -- TOML
  register("terraformls", {})
  register("tflint", {})
  register("vimls", {})
  register("yamlls", {
    schemaStore = { enable = true },
    settings = {
      yaml = {
        keyOrdering = false,
      },
    },
  })
  register("eslint", {})

  register("denols", {
    init_options = {
      lint = true,
      unstable = true,
    },
    single_file_support = false,
    root_dir = function(path)
      local marker = require("climbdir.marker")
      local found = require("climbdir").climb(path, marker.one_of(marker.has_readable_file("deno.json"), marker.has_readable_file("deno.jsonc"), marker.has_directory("denops")), {
        halt = marker.one_of(marker.has_readable_file("package.json"), marker.has_directory("node_modules")),
      })
      if found then
        vim.b[vim.fn.bufnr()].deno_deps_candidate = found .. "/deps.ts"
      end
      return found
    end,
  }, true) -- uses global deno, so it should not be installed by Mason
  register("vtsls", {
    settings = {
      typescript = {
        importModuleSpecifier = "relative",
        inlayHints = {
          parameterNames = {
            enabled = "literals",
            suppressWhenArgumentMatchesName = true,
          },
          parameterTypes = { enabled = true },
          variableTypes = { enabled = false },
          propertyDeclarationTypes = { enabled = true },
          functionLikeReturnTypes = { enabled = true },
          enumMemberValues = { enabled = true },
        },
      },
    },
    root_dir = function(path)
      local marker = require("climbdir.marker")
      return require("climbdir").climb(path, marker.one_of(marker.has_readable_file("package.json"), marker.has_directory("node_modules")), {
        halt = marker.has_readable_file("deno.json"),
      })
    end,
    single_file_support = false,
    filetypes = {
      "javascript",
      "javascriptreact",
      "javascript.jsx",
      "typescript",
      "typescriptreact",
      "typescript.tsx",
    },
  })
end

---@type LazySpec[]
local spec = {
  {
    "neovim/nvim-lspconfig",
    config = function()
      register_lsp_servers()
      setup_lsp_global()
      setup_lsp_keymap()
    end,
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "kyoh86/climbdir.nvim",
      "lukas-reineke/lsp-format.nvim",
      -- make easier setup mason & lspconfig
      "williamboman/mason-lspconfig.nvim",
      -- make JSON LSP more strict
      "b0o/schemastore.nvim",
      -- make lua-lsp more gentle
      {
        "folke/neodev.nvim",
        config = true,
      },
    },
    event = { "VeryLazy" },
  },
  -- install LSP's automatically
  "williamboman/mason.nvim",
  {
    -- update all mason's LSP automatically
    "RubixDev/mason-update-all",
    config = function()
      local g = vim.api.nvim_create_augroup("kyoh86-plug-update-mason", { clear = true })
      vim.api.nvim_create_autocmd("User", {
        group = g,
        pattern = "LazyUpdate",
        callback = function()
          require("mason-update-all").update_all()
        end,
        desc = "Run mason-update-all after packer.sync()",
      })
    end,
  },
  {
    -- show progress of lsp-server
    "j-hui/fidget.nvim",
    tag = "legacy",
    config = true,
    event = { "BufReadPre" },
  },
  {
    "jose-elias-alvarez/null-ls.nvim",
    config = function()
      local null_ls = require("null-ls")
      null_ls.setup({
        diagnostics_format = "#{m} (#{s}: #{c})",
        sources = {
          null_ls.builtins.formatting.stylua,
          null_ls.builtins.formatting.scalafmt,
          null_ls.builtins.diagnostics.actionlint,
          null_ls.builtins.diagnostics.textlint.with({
            filetypes = { "markdown" },
            condition = function(utils)
              return vim.fn.executable("textlint") ~= 0 and utils.root_has_file({
                ".textlintrc",
                ".textlintrc.js",
                ".textlintrc.json",
                ".textlintrc.yml",
                ".textlintrc.yaml",
              })
            end,
          }),
        },
        on_attach = function(client, _)
          require("lsp-format").on_attach(client)
        end,
      })
    end,
    dependencies = { "williamboman/mason.nvim", "lukas-reineke/lsp-format.nvim", "jay-babu/mason-null-ls.nvim" },
  },
}
return spec
