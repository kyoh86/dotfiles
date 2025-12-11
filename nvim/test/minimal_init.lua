local function join(...)
  return table.concat({ ... }, "/")
end
local function dir_of(path)
  return path:match("(.+)/[^/]+$")
end
local script_path = vim.fs.normalize(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p"))
local script_dir = dir_of(script_path)
local test_root = script_dir
local project_root = vim.fs.normalize(join(test_root, ".."))
local vendor_root = join(test_root, ".uitest")
local nvimcore = join(vendor_root, "nvimcore")
local busted = join(vendor_root, "busted")
local luassert = join(vendor_root, "luassert")
local say = join(vendor_root, "say")
local penlight = join(vendor_root, "penlight")
local cliargs = join(vendor_root, "cliargs")
local mediator = join(vendor_root, "mediator")
local plenary = join(vendor_root, "plenary")
local runtime_dir = join(vendor_root, "runtime")

package.path = nvimcore .. "/?.lua;" .. nvimcore .. "/?/init.lua;"
  .. busted .. "/?.lua;" .. busted .. "/?/init.lua;"
  .. luassert .. "/?.lua;" .. luassert .. "/?/init.lua;"
  .. say .. "/?.lua;" .. say .. "/?/init.lua;"
  .. penlight .. "/lua/?.lua;" .. penlight .. "/lua/?/init.lua;"
  .. cliargs .. "/?.lua;" .. cliargs .. "/?/init.lua;"
  .. mediator .. "/?.lua;" .. mediator .. "/?/init.lua;"
  .. plenary .. "/lua/?.lua;" .. plenary .. "/lua/?/init.lua;"
  .. package.path
vim.o.termguicolors = true
vim.o.guicursor = ""
vim.env.NVIM_PRG = vim.env.NVIM_PRG or vim.v.progpath
if not vim.env.NVIM_APPNAME or vim.env.NVIM_APPNAME == "" then
  vim.env.NVIM_APPNAME = "nvim-uitest"
end
vim.env.XDG_RUNTIME_DIR = vim.env.XDG_RUNTIME_DIR or runtime_dir
vim.g.loaded_remote_plugins = 1
vim.o.shadafile = "NONE"
vim.opt.runtimepath:append(plenary)
vim.opt.runtimepath:append(busted)
vim.opt.runtimepath:append(luassert)
vim.opt.runtimepath:append(say)
vim.opt.runtimepath:append(penlight)
vim.opt.runtimepath:append(cliargs)
vim.opt.runtimepath:append(mediator)
vim.opt.runtimepath:append(nvimcore)
vim.opt.runtimepath:append(project_root)
