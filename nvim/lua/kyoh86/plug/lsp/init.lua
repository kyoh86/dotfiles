local setup_keymap = require("kyoh86.plug.lsp.keymap")

--- LSPで表示されるDiagnosticsのフォーマット
local function format_diagnostics(diag)
  if diag.code then
    return string.format("[%s](%s): %s", diag.source, diag.code, diag.message)
  else
    return string.format("[%s]: %s", diag.source, diag.message)
  end
end

local diagnostic_config = {
  underline = true,
  update_in_insert = true,
  virtual_text = {
    severity = vim.diagnostic.severity.WARN,
    source = true,
    format = format_diagnostics,
  },
  float = {
    focusable = true,
    border = "rounded",
    format = format_diagnostics,
    header = {},
    source = true,
    scope = "line",
  },
  signs = true,
  severity_sort = true,
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

  require("kyoh86.lib.scheme").onSchemeChanged(function(colors_name)
    kyoh86.ensure(colors_name, function(m)
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
        m.palette.brightgreen.gui,
        m.palette.brightgreen.cterm,
        m.palette.black.gui,
        m.palette.black.cterm,
        m.palette.gradation3.gui,
        m.palette.gradation3.cterm,
        m.palette.black.gui,
        m.palette.black.cterm,
        m.palette.brightblue.gui,
        m.palette.brightblue.cterm,
        m.palette.black.gui,
        m.palette.black.cterm,
        m.palette.brightred.gui,
        m.palette.brightred.cterm,
        m.palette.black.gui,
        m.palette.black.cterm,
        m.palette.red.gui,
        m.palette.red.cterm
      ))
      -- highlightを設定する
      vim.api.nvim_set_hl(0, "LspInlayHint", {
        fg = m.colors.brightgreen,
      })
    end)
  end, true)

  -- 随時表示されるDiagnosticsの設定
  vim.diagnostic.config(diagnostic_config)

  -- サーバー毎の設定を反映させる
  -- NOTE: mason, mason-lspconfig より後にsetupを呼び出す必要がある
  for name, config in pairs(lsp_config_table) do
    kyoh86.ensure("lspconfig", function(m)
      m[name].setup(config)
    end)
  end
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

-- フォーマットが重いときのためにnoautocmdでフォーマットをスキップできるコマンドを用意する
vim.api.nvim_create_user_command("W", "noautocmd w", {})
vim.api.nvim_create_user_command("Wa", "noautocmd wa", {})
vim.api.nvim_create_user_command("WA", "noautocmd wa", {})

--- Attach時の設定
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client == nil then
      return
    end

    -- ファイル保存時に自動でフォーマットする
    -- vtslsがassignされている場合はvtsls、efmがアサインされている場合はefm
    vim.api.nvim_create_autocmd("BufWritePre", {
      desc = "ファイル保存時に自動でフォーマットする",
      group = vim.api.nvim_create_augroup(string.format("kyoh86-plug-lsp-format-buf-%d", bufnr), { clear = true }),
      buffer = bufnr,
      callback = function()
        local vtsls = vim.lsp.get_clients({ bufnr = bufnr, name = "vtsls" })
        local name = #vtsls > 0 and "vtsls" or "efm"
        vim.lsp.buf.format({
          name = name,
          timeout_ms = 2000,
        })
      end,
    })

    local f = require("kyoh86.lib.func")
    -- hoverの表示に表示元(source)を表示
    vim.keymap.set(
      "n",
      "<leader>lih",
      f.bind_all(vim.lsp.buf.hover, {
        border = "single",
        title = " " .. client.name .. " ",
      }),
      { remap = false, silent = true, desc = "カーソル下のシンボルの情報を表示する" }
    )
    vim.keymap.set(
      "n",
      "<leader>lis",
      f.bind_all(vim.lsp.buf.signature_help, {
        border = "single",
        title = " " .. client.name .. " ",
      }),
      { remap = false, silent = true, desc = "カーソル下のシンボルのシグネチャを表示する" }
    )

    if client.server_capabilities.inlayHintProvider then
      vim.b.kyoh86_plug_lsp_inlay_hint_enabled = true
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
  register("astro", {})
  register("bashls", {})
  register("biome", {})
  register("cssls", {})
  register("cssmodules_ls", {})
  register("denols", require("kyoh86.plug.lsp.denols"), true) -- uses global deno, so it should not be installed by Mason
  register("dockerls", {})
  register("efm", require("kyoh86.plug.lsp.efm"))
  register("eslint", {})
  register("gopls", require("kyoh86.plug.lsp.gopls"))
  register("html", {})
  register("jsonls", require("kyoh86.plug.lsp.jsonls"))
  register("jqls", {})
  register("lemminx", {}) -- XML
  register("lua_ls", require("kyoh86.plug.lsp.luals"))
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
  register("rust_analyzer", require("kyoh86.plug.lsp.rust"), true)
  register("sqlls", {})
  register("stylelint_lsp", {})
  register("svelte", {})
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
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = "luvit-meta/library", words = { "vim%.uv" } },
        "lazy.nvim",
        "plenary.nvim",
        { path = "wezterm-types", mods = { "wezterm" } },
      },
    },
  },
  { "justinsgithub/wezterm-types" },
  { "Bilal2453/luvit-meta", lazy = true }, -- optional `vim.uv` typings
  {
    "neovim/nvim-lspconfig",
    config = function()
      register_lsp_servers()
      setup_lsp_global()
      setup_keymap()
    end,
    dependencies = {
      --- "cmp-nvim-lsp",
      "climbdir.nvim",
      "mason-lspconfig.nvim",
      "schemastore.nvim",
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
