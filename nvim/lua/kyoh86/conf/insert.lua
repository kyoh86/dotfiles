-- ref: /usr/local/share/nvim/runtime/lua/vim/_defaults.lua

vim.keymap.set('n', '<leader>O', function()
  vim.go.operatorfunc = "v:lua.require'vim._buf'.space_above"
  return 'g@l'
end, { expr = true, desc = 'カーソルの上に空の行を挿入する' })

vim.keymap.set('n', '<leader>o', function()
  vim.go.operatorfunc = "v:lua.require'vim._buf'.space_below"
  return 'g@l'
end, { expr = true, desc = 'カーソルの下に空の行を挿入する' })
