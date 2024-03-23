---@type LazySpec[]
local spec = {
  {
    "Shougo/ddc.vim",
    config = function()
      local func = require("kyoh86.lib.func")
      --- ddc本体の設定の読み込み
      --ref: ../../../denops/kyoh86/plug/ddc.ts
      vim.fn["ddc#custom#load_config"](vim.fn.stdpath("config")--[[@as string]] .. "/denops/kyoh86/plug/ddc.ts")

      --- ddcのKeymap設定
      local pumap = function(lh, rh)
        vim.keymap.set("i", lh, function()
          if not vim.fn["pum#visible"]() then
            return lh
          end
          rh()
        end, { remap = true, expr = true })
      end
      pumap("<cr>", func.bind_all(vim.fn["pum#map#confirm"]))
      pumap("<esc>", func.bind_all(vim.fn["ddc#hide"], "Manual"))
      pumap("<C-e>", func.bind_all(vim.fn["ddc#map#extend"], vim.api.nvim_replace_termcodes("<C-e>", true, true, true)))
      pumap("<C-n>", func.bind_all(vim.fn["pum#map#select_relative"], 1))
      pumap("<C-p>", func.bind_all(vim.fn["pum#map#select_relative"], -1))
      pumap("<C-o>", func.bind_all(vim.fn["pum#map#confirm_word"]))

      vim.keymap.set("i", "<C-Space>", func.bind_all(vim.fn["ddc#map#manual_complete"]), {})

      --- pumの設定
      vim.fn["pum#set_option"]({
        border = "single",
        padding = true,
        preview = true,
      })
      --- ddc利用に必要な周辺の設定
      vim.opt.completeopt:append("noinsert")
      vim.opt.shortmess:append("c")

      vim.fn["ddc#enable"]()
    end,
    dependencies = { "pum.vim", "denops.vim" },
  },
  {
    "Shougo/ddc-ui-pum",
    dependencies = { "pum.vim", "denops.vim" },
  },
  {
    "Shougo/pum.vim",
    dependencies = { "denops.vim" },
  },

  { "Shougo/ddc-filter-converter_remove_overlap", dependencies = { "ddc.vim", "denops.vim" } },
  { "Shougo/ddc-filter-converter_truncate_abbr", dependencies = { "ddc.vim", "denops.vim" } },
  { "Shougo/ddc-filter-matcher_head", dependencies = { "ddc.vim", "denops.vim" } },
  { "Shougo/ddc-filter-matcher_length", dependencies = { "ddc.vim", "denops.vim" } },
  { "Shougo/ddc-filter-matcher_prefix", dependencies = { "ddc.vim", "denops.vim" } },
  { "Shougo/ddc-filter-matcher_vimregexp", dependencies = { "ddc.vim", "denops.vim" } },
  { "Shougo/ddc-filter-sorter_head", dependencies = { "ddc.vim", "denops.vim" } },
  { "Shougo/ddc-filter-sorter_rank", dependencies = { "ddc.vim", "denops.vim" } },
  { "Shougo/ddc-source-cmdline", dependencies = { "ddc.vim", "denops.vim" } },
  { "Shougo/ddc-source-cmdline-history", dependencies = { "ddc.vim", "denops.vim" } },
  { "Shougo/ddc-source-input", dependencies = { "ddc.vim", "denops.vim" } },
  { "Shougo/ddc-source-line", dependencies = { "ddc.vim", "denops.vim" } },
  { "Shougo/ddc-source-lsp", dependencies = { "ddc.vim", "denops.vim" } },
  { "Shougo/ddc-source-nvim-lua", dependencies = { "ddc.vim", "denops.vim" } },
  { "Shougo/ddc-source-copilot", dependencies = { "ddc.vim", "denops.vim" } },
  { "kyoh86/ddc-source-ollama", dev = true, dependencies = { "ddc.vim", "denops.vim" } },
  { "matsui54/ddc-buffer", dependencies = { "ddc.vim", "denops.vim" } },
  { "Shougo/ddc-ui-inline", dependencies = { "ddc.vim", "denops.vim" } },
  { "uga-rosa/ddc-source-vsnip", event = "VeryLazy", dependencies = { "ddc.vim", "denops.vim", "vim-vsnip" } },
  {
    "hrsh7th/vim-vsnip",
    init = function()
      vim.g.vsnip_snippet_dir = vim.fn.expand("~/.config/nvim/vsnip")
      vim.g.vsnip_snippet_dirs = {
        vim.g.vsnip_snippet_dir,
        vim.fn.expand("~/.config/aia/vsnip"),
      }
    end,
    config = function()
      -- Expand, jump forward or backward
      local expand = function()
        return vim.fn["vsnip#available"](1) ~= 0 and "<plug>(vsnip-expand-or-jump)" or "<c-l>"
      end
      local jump_next = function()
        return vim.fn["vsnip#jumpable"](1) ~= 0 and "<plug>(vsnip-jump-next)" or "<tab>"
      end
      local jump_prev = function()
        return vim.fn["vsnip#jumpable"](-1) ~= 0 and "<plug>(vsnip-jump-prev)" or "<s-tab>"
      end

      vim.keymap.set("i", "<c-l>", expand, { expr = true, desc = "expand snipet or jump to filler" })
      vim.keymap.set("s", "<c-l>", expand, { expr = true, desc = "expand snipet or jump to filler" })
      vim.keymap.set("i", "<tab>", jump_next, { expr = true, desc = "jump to next snippet filler" })
      vim.keymap.set("s", "<tab>", jump_next, { expr = true, desc = "jump to next snippet filler" })
      vim.keymap.set("i", "<s-tab>", jump_prev, { expr = true, desc = "jump to previous snippet filler" })
      vim.keymap.set("s", "<s-tab>", jump_prev, { expr = true, desc = "jump to previous snippet filler" })
    end,
    event = "VeryLazy",
  },
  {
    "matsui54/denops-popup-preview.vim",
    enabled = false,
    config = function()
      vim.fn["popup_preview#enable"]()
      vim.g.popup_preview_config = {
        border = false,
      }
    end,
  },
  -- { import = "kyoh86.plug.ddc.source" },
  -- { import = "kyoh86.plug.ddu.filter" },
  -- { import = "kyoh86.plug.ddu.kind" },
  -- { import = "kyoh86.plug.ddu.ui" },
}
return spec
