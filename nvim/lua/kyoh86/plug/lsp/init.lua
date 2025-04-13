local setup_keymap = require("kyoh86.plug.lsp.keymap")

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

    if client.server_capabilities.inlayHintProvider then
      vim.b.kyoh86_plug_lsp_inlay_hint_enabled = true
    end

    client.server_capabilities.semanticTokensProvider = nil

    --- Attach時の設定: 特定のBuffer名と特定のClient名の組み合わせで、LSP Clientを無効化する
    --- バッファ名のパターンをPlain textとして扱いたい（パターンではなくLiteral matchとする）場合はplain = trueを指定する
    local disabled_clients = {
      eslint = { {
        name = "upmind-inc/upmind-server",
        plain = true,
      } },
    }
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    local lsp_local_disable = disabled_clients[client.name]
    if lsp_local_disable then
      for _, v in pairs(lsp_local_disable) do
        if string.find(bufname, v.name, 1, v.plain) then
          client:stop()
          break
        end
      end
    end

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

  local enable = function(name)
    vim.lsp.config(name, { capabilities = capabilities })
    vim.lsp.enable(name)
  end

  enable("angularls")
  enable("ansiblels")
  enable("astro")
  enable("bashls")
  enable("cssls") -- vscode-langservers-extracted
  enable("denols") -- ref: nvim/lsp/denols.lua; uses global deno, so it should not be installed by Mason
  enable("dockerls")
  enable("efm") -- ref: nvim/lsp/efm.lua;
  enable("eslint")
  enable("gopls") -- ref: nvim/lsp/gopls.lua; uses global gopls, so it should not be installed by Mason
  enable("html") -- vscode-langservers-extracted
  enable("jsonls") -- ref: nvim/lsp/jsonls.lua; vscode-langservers-extracted
  enable("jqls")
  enable("lua_ls") -- ref: nvim/lsp/lua_ls.lua;
  enable("metals") -- Scala (metals): without installation with mason.nvim
  enable("prismals") -- Prisma (TypeScript DB ORM)
  enable("rust_analyzer") -- ref: nvim/lsp/rust_analyzer.lua;
  enable("sqls")
  enable("stylelint_lsp")
  enable("svelte")
  enable("taplo") -- TOML
  enable("terraformls")
  enable("vimls")
  enable("vtsls") -- ref: nvim/lsp/vtsls.lua;
  enable("yamlls") -- ref: nvim/lsp/yamlls.lua;
end

---@type LazySpec[]
local spec = {
  {
    "neovim/nvim-lspconfig",
    config = function()

      -- フォーマットが重いときのためにnoautocmdでフォーマットをスキップできるコマンドを用意する
      vim.api.nvim_create_user_command("W", "noautocmd w", {})
      vim.api.nvim_create_user_command("Wa", "noautocmd wa", {})
      vim.api.nvim_create_user_command("WA", "noautocmd wa", {})

      vim.lsp.set_log_level(vim.log.levels.OFF)

      -- highlightを設定する
      require("kyoh86.lib.scheme").onSchemeChanged(function(colors_name)
        kyoh86.ensure(colors_name, function(m)
          vim.api.nvim_set_hl(0, "LspInlayHint", {
            fg = m.colors.brightgreen,
          })
        end)
      end, true)
      register_lsp_servers()
      setup_keymap()
    end,
    dependencies = {
      --- "cmp-nvim-lsp",
      "climbdir.nvim",
      "schemastore.nvim",
    },
    event = { "BufReadPre", "BufNewFile" },
  },
  { "kyoh86/climbdir.nvim", lazy = true },
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
  {
    "artemave/workspace-diagnostics.nvim",
    dependencies = {
      "nvim-lspconfig",
    },
    config = function()
      vim.api.nvim_set_keymap("n", "<leader>lxd", "", {
        noremap = true,
        callback = function()
          for _, client in ipairs(vim.lsp.get_clients()) do
            require("workspace-diagnostics").populate_workspace_diagnostics(client, 0)
          end
        end,
      })
    end,
  },
}
return spec
