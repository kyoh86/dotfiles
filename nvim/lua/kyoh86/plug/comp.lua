--- 補完とスニペットの設定

--- 補完の設定
local function setup_comp()
  vim.opt.omnifunc = "syntaxcomplete#Complete"
  local cmp = require("cmp")

  -- テキスト内の補完: lsp, vsnip
  cmp.setup.filetype({ "ddu-ff-filter" }, { enabled = false })
  cmp.setup({
    enabled = true,
    snippet = {
      expand = function(args)
        vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
      end,
    },
    window = {
      completion = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
      ["<C-d>"] = cmp.mapping.scroll_docs(-4),
      ["<C-f>"] = cmp.mapping.scroll_docs(4),
      ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
      ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
      ["<C-Space>"] = cmp.mapping.complete(),
      ["<CR>"] = cmp.mapping.confirm({ select = true }),
      ["<C-y>"] = cmp.mapping.confirm({ select = true }),
      ["<C-l>"] = cmp.mapping.complete_common_string(),
    }),
    completion = {
      autocomplete = false,
    },
    formatting = {
      ---@type fun(entry: cmp.Entry, vim_item: vim.CompletedItem): vim.CompletedItem
      format = function(entry, vim_item)
        if entry.source.name == "nvim_lsp" then
          local client_name = vim.tbl_get(entry, "source", "source", "client", "name")
          vim_item.menu = client_name
        end
        return vim_item
      end,
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
end

-- snippetの設定
local function setup_snip()
  vim.g.vsnip_snippet_dir = vim.fn.expand("~/.config/nvim/vsnip")
  vim.g.vsnip_snippet_dirs = {
    vim.g.vsnip_snippet_dir,
    vim.fn.expand("~/.config/aia/vsnip"),
  }

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
end

---@type LazySpec[]
local spec = {
  {
    "golang/vscode-go",
    ft = { "go" },
  },
  {
    "hrsh7th/cmp-nvim-lua",
    lazy = true,
  },
  {
    "hrsh7th/cmp-nvim-lsp",
    lazy = true,
  },
  {
    "hrsh7th/cmp-cmdline",
    lazy = true,
  },
  {
    "hrsh7th/cmp-path",
    lazy = true,
  },
  {
    "hrsh7th/cmp-vsnip",
    lazy = true,
  },
  {
    "hrsh7th/vim-vsnip",
    lazy = true,
  },
  {
    "rafamadriz/friendly-snippets",
    lazy = true,
  },
  {
    "hrsh7th/nvim-cmp",
    config = function()
      setup_comp()
      setup_snip()
    end,
    dependencies = {
      "vscode-go",
      "cmp-nvim-lua",
      "cmp-nvim-lsp",
      "cmp-cmdline",
      "cmp-path",
      "cmp-vsnip",
      "vim-vsnip",
      "friendly-snippets",
    },
  },
  {
    "uga-rosa/cmp-skkeleton",
    dependencies = { "skkeleton", "nvim-cmp" },
  },
}
return spec
