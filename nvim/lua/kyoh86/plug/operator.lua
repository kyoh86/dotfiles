---@type LazySpec[]
local spec = {
  {
    "kana/vim-textobj-user",
    lazy = true,
  },
  {
    "kana/vim-operator-user",
    lazy = true,
  },
  {
    "arthurxavierx/vim-caser",
    dependencies = { "vim-textobj-user" },
  },
  {
    "kana/vim-textobj-line",
    dependencies = { "vim-textobj-user" },
  },
  {
    "kana/vim-textobj-entire",
    dependencies = { "vim-textobj-user" },
  },
  {
    "kana/vim-operator-replace",
    keys = {
      { "_", "<Plug>(operator-replace)", mode = { "" }, desc = "replace target with the register" },
    },
    dependencies = { "vim-operator-user" },
  },
  {
    "osyo-manga/vim-operator-jump_side",
    dependencies = { "vim-operator-user" },
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
        input = { vim.keycode("<c-f>") },
      })
      table.insert(recipes, {
        buns = { "<", '">"' },
        kind = { "add" },
        cursor = "head",
        command = { "startinsert" },
        input = { "g" },
      })
      table.insert(recipes, {
        external = { "i<", vim.keycode([[<plug>(textobj-functioncall-generics-a)]]) },
        noremap = 0,
        kind = { "delete", "replace", "query" },
        input = { "g" },
      })
      vim.g["operator#sandwich#recipes"] = recipes
      vim.keymap.set({ "x", "n" }, "s", "<nop>", { remap = false, desc = "sandwich operations" })
      vim.keymap.set("n", "sfa", "<plug>(operator-sandwich-add-query1st)<c-f>", { desc = "wrap target as argument" })
      vim.keymap.set("x", "sfa", "<plug>(operator-sandwich-add)<c-f>", { desc = "wrap target as argument" })
      vim.keymap.set("n", "sc", "<plug>(operator-sandwich-replace)<plug>(operator-sandwich-release-count)<plug>(textobj-sandwich-query-a)", { silent = true, desc = "replace sandwich" })
      vim.keymap.set("n", "scb", "<plug>(operator-sandwich-replace)<plug>(operator-sandwich-release-count)<plug>(textobj-sandwich-auto-a)", { silent = true, desc = "replace sandwich for the typical brackets" })
    end,
    dependencies = { "vim-textobj-functioncall" },
  },
  {
    "machakann/vim-textobj-functioncall",
    config = function()
      vim.g.textobj_functioncall_generics_patterns = {
        {
          header = [[\<\%(\h\k*\.\)*\h\k*]],
          bra = "<",
          ket = ">",
          footer = "",
        },
      }

      -- Genericsのカッコ（<>）絡み
      vim.keymap.set("o", "<plug>(textobj-functioncall-generics-i)", ":<c-u>call textobj#functioncall#ip('o', g:textobj_functioncall_generics_patterns)<cr>", { remap = false })
      vim.keymap.set("x", "<plug>(textobj-functioncall-generics-i)", ":<c-u>call textobj#functioncall#ip('x', g:textobj_functioncall_generics_patterns)<cr>", { remap = false })
      vim.keymap.set("o", "<plug>(textobj-functioncall-generics-a)", ":<c-u>call textobj#functioncall#i('o', g:textobj_functioncall_generics_patterns)<cr>", { remap = false })
      vim.keymap.set("x", "<plug>(textobj-functioncall-generics-a)", ":<c-u>call textobj#functioncall#i('x', g:textobj_functioncall_generics_patterns)<cr>", { remap = false })

      vim.keymap.set("o", "ig", "<Plug>(textobj-functioncall-generics-i)", {})
      vim.keymap.set("x", "ig", "<Plug>(textobj-functioncall-generics-i)", {})
      vim.keymap.set("o", "ag", "<Plug>(textobj-functioncall-generics-a)", {})
      vim.keymap.set("x", "ag", "<Plug>(textobj-functioncall-generics-a)", {})

      -- Functionの呼び出し絡み
      vim.keymap.set({ "o", "x" }, "iF", "<plug>(textobj-functioncall-innerparen-i)", { silent = true, remap = false, desc = "a textobj in the function calling" })
      vim.keymap.set({ "o", "x" }, "aF", "<plug>(textobj-functioncall-a)", { silent = true, remap = false, desc = "a textobj around the function calling" })
    end,
    dependencies = { "vim-textobj-user" },
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
