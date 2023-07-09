--- 補完とスニペットの設定

--- 補完の設定
local function setup_comp()
  vim.opt.omnifunc = "syntaxcomplete#Complete"
  vim.opt.completeopt = { "menu", "menuone", "noselect" }
  local cmp = require("cmp")

  -- テキスト内の補完: lsp, vsnip
  cmp.setup.filetype({ "ddu-ff-filter" }, { enabled = false })
  cmp.setup({
    enabled = true,
    snippet = {
      expand = function(args)
        kyoh86.fa.vsnip.anonymous(args.body) -- For `vsnip` users.
      end,
    },
    window = {
      completion = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
      ["<C-d>"] = cmp.mapping.scroll_docs(-4),
      ["<C-f>"] = cmp.mapping.scroll_docs(4),
      ["<C-x><C-s>"] = cmp.mapping.complete(),
      ["<CR>"] = cmp.mapping.confirm({ select = true }),
    }),
    completion = {
      autocomplete = false,
      keyword_length = 0,
    },
    experimental = {
      ghost_text = true,
    },
    sources = cmp.config.sources({
      { name = "nvim_lsp" },
      { name = "nvim_lua" },
      { name = "vsnip" },
      { name = "skkeleton" },
    }),
  })

  cmp.setup.filetype({ "TelescopePrompt" }, {
    enabled = false,
  })
end

-- snippetの設定
local function setup_snip()
  vim.g.vsnip_snippet_dirs = {
    vim.fn.expand("~/.config/nvim/vsnip"),
    vim.fn.expand("~/.config/aia/vsnip"),
  }

  -- Expand, jump forward or backward
  local expand = function()
    return kyoh86.fa.vsnip.available(1) ~= 0 and "<plug>(vsnip-expand-or-jump)" or "<c-l>"
  end
  local jump_next = function()
    return kyoh86.fa.vsnip.jumpable(1) ~= 0 and "<plug>(vsnip-jump-next)" or "<tab>"
  end
  local jump_prev = function()
    return kyoh86.fa.vsnip.jumpable(-1) ~= 0 and "<plug>(vsnip-jump-prev)" or "<s-tab>"
  end

  vim.keymap.set("i", "<c-l>", expand, { expr = true, desc = "expand snipet or jump to filler" })
  vim.keymap.set("s", "<c-l>", expand, { expr = true, desc = "expand snipet or jump to filler" })
  vim.keymap.set("i", "<tab>", jump_next, { expr = true, desc = "jump to next snippet filler" })
  vim.keymap.set("s", "<tab>", jump_next, { expr = true, desc = "jump to next snippet filler" })
  vim.keymap.set("i", "<s-tab>", jump_prev, { expr = true, desc = "jump to previous snippet filler" })
  vim.keymap.set("s", "<s-tab>", jump_prev, { expr = true, desc = "jump to previous snippet filler" })
end

---@type LazySpec
local spec = { {
  "hrsh7th/nvim-cmp",
  config = function()
    setup_comp()
    setup_snip()
  end,
  dependencies = {
    {
      "golang/vscode-go",
      ft = { "go" },
    },
    { "hrsh7th/cmp-nvim-lua" },
    { "hrsh7th/cmp-nvim-lsp" },
    { "hrsh7th/cmp-cmdline" },
    { "hrsh7th/cmp-path" },
    { "hrsh7th/cmp-vsnip" },
    { "hrsh7th/vim-vsnip" },
  },
}, {
  "uga-rosa/cmp-skkeleton",
  dependencies = { "vim-skk/skkeleton", "hrsh7th/nvim-cmp" },
} }
return spec
