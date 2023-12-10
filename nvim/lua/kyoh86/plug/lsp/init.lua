local setup_keymap = require("kyoh86.plug.lsp.keymap")

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
  vim.lsp.set_log_level(vim.log.levels.OFF)
  kyoh86.ensure("mason", function(m)
    m.setup({
      log_level = vim.log.levels.OFF,
    })
  end)
  kyoh86.ensure("mason-lspconfig", function(m)
    m.setup({
      ensure_installed = lsp_server_list,
    })
  end)
  kyoh86.ensure("lsp-format", function(m)
    m.setup({
      go = {},
      javascript = {},
      lua = {},
      css = {},
      terraform = {},
      typescript = {},
    })
  end)

  -- 随時表示されるDiagnosticsのフォーマット設定
  vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
    update_in_insert = false,
    float = diagnosis_config,
    virtual_text = diagnosis_config,
  })

  vim.diagnostic.config({ virtual_text = true, signs = false })

  -- hoverの表示に表示元(source)を表示
  vim.api.nvim_create_autocmd("LspAttach", {
    once = true,
    callback = function()
      vim.lsp.handlers["textDocument/hover"] = function(_, results, ctx, conf)
        local client = vim.lsp.get_client_by_id(ctx.client_id)
        local config = conf or {}
        if client ~= nil then
          config = vim.tbl_deep_extend("force", config, {
            border = "single",
            title = " " .. client.name .. " ",
          })
        end
        vim.lsp.handlers.hover(_, results, ctx, config)
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
    if client == nil then
      return
    end
    if client.server_capabilities.documentFormattingProvider then
      kyoh86.ensure("lsp-format", function(m)
        m.on_attach(client)
      end)
    end
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
  register("denols", require("kyoh86.plug.lsp.denols"), true) -- uses global deno, so it should not be installed by Mason
  register("dockerls", {})
  register("efm", require("kyoh86.plug.lsp.efm"))
  register("eslint", {})
  register("gopls", require("kyoh86.plug.lsp.gopls"))
  register("graphql", {})
  register("html", {})
  register("jsonls", require("kyoh86.plug.lsp.jsonls"))
  register("lemminx", {}) -- XML
  register("lua_ls", require("kyoh86.plug.lsp.luals"))
  register("metals", {}, true) -- Scala (metals): without installation with mason.nvim
  register("prismals", {}) -- Prisma (TypeScript DB ORM)
  register("pylsp", {})
  register("pyright", {})
  register("rust_analyzer", require("kyoh86.plug.lsp.rust"), true)
  register("sqlls", {})
  register("stylelint_lsp", {})
  register("taplo", {}) -- TOML
  register("terraformls", {})
  register("tflint", {})
  register("vimls", {})
  register("vtsls", require("kyoh86.plug.lsp.vtsls"))
  register("yamlls", {
    settings = {
      yaml = {
        schemaStore = { enable = true },
        keyOrdering = false,
      },
    },
  })
end

---@type LazySpec[]
local spec = {
  { "hrsh7th/cmp-nvim-lsp", lazy = true },
  { "kyoh86/climbdir.nvim", lazy = true },
  -- make easier setup mason & lspconfig
  { "williamboman/mason-lspconfig.nvim", lazy = true },
  -- make JSON LSP more strict
  { "b0o/schemastore.nvim", lazy = true },
  {
    -- make lua-lsp more gentle
    "folke/neodev.nvim",
    config = true,
    lazy = true,
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      register_lsp_servers()
      setup_lsp_global()
      setup_keymap(diagnosis_config)
    end,
    dependencies = {
      "cmp-nvim-lsp",
      "climbdir.nvim",
      "lsp-format.nvim",
      "mason-lspconfig.nvim",
      "schemastore.nvim",
      "neodev.nvim",
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
    "ray-x/lsp_signature.nvim",
    event = "VeryLazy",
    opts = {},
    config = function(_, opts)
      require("lsp_signature").setup(opts)
    end,
  },
  { "williamboman/mason.nvim", lazy = true },
  { "lukas-reineke/lsp-format.nvim", lazy = true },
}
return spec
