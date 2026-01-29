---@type LazySpec[]
local spec = {
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- フォーマットが重いときのためにnoautocmdでフォーマットをスキップできるコマンドを用意する
      vim.api.nvim_create_user_command("W", "noautocmd w", {})
      vim.api.nvim_create_user_command("Wa", "noautocmd wa", {})
      vim.api.nvim_create_user_command("WA", "noautocmd wa", {})

      -- highlightを設定する
      require("kyoh86.lib.scheme").onSchemeChanged(function(colors_name)
        kyoh86.ensure(colors_name, function(m)
          vim.api.nvim_set_hl(0, "LspInlayHint", {
            fg = m.colors.brightgreen,
          })
        end)
      end, true)

      require("kyoh86.plug.lsp.register")()
      require("kyoh86.plug.lsp.keymap")()
      --- Attach時の設定
      local au = require("kyoh86.lib.autocmd")
      au.group("kyoh86.plug.lsp.init", true):hook("LspAttach", {
        callback = function(args)
          require("kyoh86.plug.lsp.attach")(args)
        end,
      })
    end,
    dependencies = {
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
