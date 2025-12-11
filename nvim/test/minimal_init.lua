package.path = "nvim/test/.uitest/nvimcore" .. "/?.lua;" .. "nvim/test/.uitest/nvimcore" .. "/?/init.lua;"
  .. "nvim/test/.uitest/busted" .. "/?.lua;" .. "nvim/test/.uitest/busted" .. "/?/init.lua;"
  .. "nvim/test/.uitest/luassert" .. "/?.lua;" .. "nvim/test/.uitest/luassert" .. "/?/init.lua;"
  .. "nvim/test/.uitest/say" .. "/?.lua;" .. "nvim/test/.uitest/say" .. "/?/init.lua;"
  .. "nvim/test/.uitest/penlight" .. "/lua/?.lua;" .. "nvim/test/.uitest/penlight" .. "/lua/?/init.lua;"
  .. "nvim/test/.uitest/cliargs" .. "/?.lua;" .. "nvim/test/.uitest/cliargs" .. "/?/init.lua;"
  .. "nvim/test/.uitest/mediator" .. "/?.lua;" .. "nvim/test/.uitest/mediator" .. "/?/init.lua;"
  .. "nvim/test/.uitest/plenary" .. "/lua/?.lua;" .. "nvim/test/.uitest/plenary" .. "/lua/?/init.lua;"
  .. package.path
vim.o.termguicolors = true
vim.o.guicursor = ""
vim.env.NVIM_PRG = vim.env.NVIM_PRG or vim.v.progpath
vim.opt.runtimepath:append("nvim/test/.uitest/plenary")
vim.opt.runtimepath:append("nvim/test/.uitest/busted")
vim.opt.runtimepath:append("nvim/test/.uitest/luassert")
vim.opt.runtimepath:append("nvim/test/.uitest/say")
vim.opt.runtimepath:append("nvim/test/.uitest/penlight")
vim.opt.runtimepath:append("nvim/test/.uitest/cliargs")
vim.opt.runtimepath:append("nvim/test/.uitest/mediator")
vim.opt.runtimepath:append("nvim/test/.uitest/nvimcore")
vim.opt.runtimepath:append("nvim")
