local setup_keymap = require("kyoh86.plug.lsp.keymap")
local setup_context = require("kyoh86.plug.lsp.context")

--- LSPで表示されるDiagnosticsのフォーマット
local function format_diagnostics(diag)
  if diag.code then
    return string.format("[%s](%s): %s", diag.source, diag.code, diag.message)
  else
    return string.format("[%s]: %s", diag.source, diag.message)
  end
end

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

  local diagnostic_config = {
    underline = true,
    update_in_insert = true,
    virtual_text = {
      severity = vim.diagnostic.severity.WARN,
      source = true,
      format = format_diagnostics,
    },
    float = {
      focusable = false,
      border = "rounded",
      format = format_diagnostics,
      header = {},
      source = true,
      scope = "cursor",
    },
    signs = true,
  }

  kyoh86.ensure("momiji", function(m)
    vim.cmd(string.format(
      [[
      highlight DiagnosticFloatingOk    guibg=%s ctermbg=%s guifg=%s ctermfg=%s
      highlight DiagnosticFloatingHint  guibg=%s ctermbg=%s guifg=%s ctermfg=%s
      highlight DiagnosticFloatingInfo  guibg=%s ctermbg=%s guifg=%s ctermfg=%s
      highlight DiagnosticFloatingWarn  guibg=%s ctermbg=%s guifg=%s ctermfg=%s
      highlight DiagnosticFloatingError guibg=%s ctermbg=%s guifg=%s ctermfg=%s
    ]],
      m.palette.black.gui,
      m.palette.black.cterm,
      m.palette.lightgreen.gui,
      m.palette.lightgreen.cterm,
      m.palette.black.gui,
      m.palette.black.cterm,
      m.palette.grayscale3.gui,
      m.palette.grayscale3.cterm,
      m.palette.black.gui,
      m.palette.black.cterm,
      m.palette.lightblue.gui,
      m.palette.lightblue.cterm,
      m.palette.black.gui,
      m.palette.black.cterm,
      m.palette.lightred.gui,
      m.palette.lightred.cterm,
      m.palette.black.gui,
      m.palette.black.cterm,
      m.palette.red.gui,
      m.palette.red.cterm
    ))
  end)

  -- 随時表示されるDiagnosticsの設定
  vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, diagnostic_config)
  vim.diagnostic.config(diagnostic_config)

  -- hoverの表示に表示元(source)を表示
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

  -- サーバー毎の設定を反映させる
  -- NOTE: mason, mason-lspconfig より後にsetupを呼び出す必要がある
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
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = string.format("<buffer=%d>", bufnr),
        callback = require("kyoh86.lib.func").bind_all(vim.lsp.buf.format, {
          name = "efm",
          timeout_ms = 2000,
          -- filter = function(formatter_client)
          --   return formatter_client.name ~= "tsserver" and formatter_client.name ~= "vtsls"
          -- end,
        }),
      })
    end

    if client.server_capabilities.inlayHintProvider then
      vim.b.kyoh86_plug_lsp_inlay_hint_enabled = true
    end

    if client.server_capabilities.documentSymbolProvider then
      kyoh86.ensure("nvim-navic", function(m)
        m.attach(client, bufnr)
      end)
    end

    client.server_capabilities.semanticTokensProvider = nil
    disable_lsp(client, bufnr)
  end,
})

--- LSPサーバー毎の設定管理
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
      setup_keymap()
      setup_context()
    end,
    dependencies = {
      --- "cmp-nvim-lsp",
      "climbdir.nvim",
      "mason-lspconfig.nvim",
      "schemastore.nvim",
      "neodev.nvim",
    },
    event = { "BufReadPre", "BufNewFile" },
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
}
return spec
