vim.g.textobj_generics = { -- iG, aG (function call)で使う
  {
    ["header"] = "\\<\\%(\\h\\k*\\.\\)*\\h\\k*",
    ["bra"] = "<",
    ["ket"] = ">",
    ["footer"] = "",
  },
}

---@type LazySpec[]
local spec = {
  { "arthurxavierx/vim-caser", dependencies = { "kana/vim-textobj-user" } },
  { "kana/vim-textobj-line", dependencies = { "kana/vim-textobj-user" } },
  { "kana/vim-textobj-entire", dependencies = { "kana/vim-textobj-user" } },
  {
    "kana/vim-operator-replace",
    keys = {
      { "_", "<Plug>(operator-replace)", mode = { "" }, desc = "replace target with the register" },
    },
    dependencies = { "kana/vim-operator-user" },
  },
  {
    "osyo-manga/vim-operator-jump_side",
    dependencies = { "kana/vim-operator-user" },
    keys = {
      { "[<leader>", "<plug>(operator-jump-head)", desc = "jumps to head of the textobj" },
      { "]<leader>", "<plug>(operator-jump-tail)", desc = "jumps to tail of the textobj" },
    },
  },
  {
    "machakann/vim-sandwich",
    config = function()
      local recipes = vim.fn.deepcopy(vim.g["operator#sandwich#default_recipes"]) or {}
      table.insert(recipes, {
        buns = { "(", ")" },
        kind = { "add" },
        action = { "add" },
        cursor = "head",
        command = { "startinsert" },
        input = { vim.api.nvim_replace_termcodes("<c-f>", true, false, true) },
      })
      vim.g["operator#sandwich#recipes"] = recipes
    end,
    keys = {
      -- ignore s instead of the cl
      { "s", "<nop>", remap = false, desc = "sandwich operations" },
      { "s", "<nop>", mode = "x", remap = false, desc = "sandwich operations" },

      { "sfa", "<plug>(operator-sandwich-add-query1st)<c-f>", desc = "wrap target as argument" },
      { "sfa", "<plug>(operator-sandwich-add)<c-f>", mode = "x", desc = "wrap target as argument" },

      { "sc", "<plug>(operator-sandwich-replace)<plug>(operator-sandwich-release-count)<plug>(textobj-sandwich-query-a)", silent = true, desc = "replace sandwich" },
      { "scb", "<plug>(operator-sandwich-replace)<plug>(operator-sandwich-release-count)<plug>(textobj-sandwich-auto-a)", silent = true, desc = "replace sandwich for the typical brackets" },
    },
  },
  {
    "machakann/vim-textobj-functioncall",
    keys = {
      -- Genericsのカッコ（<>）絡み
      { "iG", '<cmd>call textobj#functioncall#ip("o", g:textobj_generics)<cr>', mode = { "x", "o" }, desc = "a textobj in the brackets for the generics (<>)" },
      { "aG", '<cmd>call textobj#functioncall#i("o", g:textobj_generics)<cr>', mode = { "x", "o" }, desc = "a textobj around the brackets for the generics (<>)" },
      -- Functionの呼び出し絡み
      { "iF", "<plug>(textobj-functioncall-innerparen-i)", mode = { "x", "o" }, desc = "a textobj in the function calling" },
      { "aF", "<plug>(textobj-functioncall-a)", mode = { "x", "o" }, desc = "a textobj around the function calling" },
    },
    dependencies = { "kana/vim-textobj-user" },
  },
  {
    "machakann/vim-swap",
    keys = {
      { "gs", "<Plug>(swap-interactive)", mode = { "n", "x" } },
      { "g<", "<Plug>(swap-prev)", mode = { "n", "x" } },
      { "g>", "<Plug>(swap-next)", mode = { "n", "x" } },
      { "i,", "<plug>(swap-textobject-i)", mode = { "o", "x" }, desc = "a testobj in the parameter" },
      { "a,", "<plug>(swap-textobject-a)", mode = { "o", "x" }, desc = "a testobj around the parameter" },
    },
  },
}
return spec
