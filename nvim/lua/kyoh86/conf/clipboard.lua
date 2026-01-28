vim.opt.clipboard = ""

vim.keymap.set({ "n", "x" }, "gd", '"*d')
vim.keymap.set({ "n", "x" }, "gy", '"*y')
vim.keymap.set({ "n", "x" }, "gp", '"*p')
vim.keymap.set({ "n", "x" }, "gP", '"*P')
vim.keymap.set({ "n", "x" }, "g_", '"*_', { remap = true })

local glaze = require("kyoh86.lib.glaze")
glaze.ensure("clipboard", function()
  if vim.fn.executable("win32yank.exe") ~= 0 then
    return "win32"
  elseif vim.fn.executable("wl-copy") ~= 0 and vim.fn.executable("wl-paste") ~= 0 then
    return "wlcopy"
  end
  return ""
end)
glaze.get_async("clipboard", function(env, fail)
  if env == "win32" then
    vim.g.clipboard = {
      name = "win32yank-wsl",
      copy = {
        ["+"] = "win32yank.exe -i --crlf",
        ["*"] = "win32yank.exe -i --crlf",
      },
      paste = {
        ["+"] = "win32yank.exe -o --lf",
        ["*"] = "win32yank.exe -o --lf",
      },
      cache_enabled = 1,
    }
  elseif env == "wlcopy" then
    vim.g.clipboard = {
      name = "wayland-copy",
      copy = {
        ["+"] = { "wl-copy", "--type", "text-plain" },
        ["*"] = { "wl-copy", "--primary", "--type", "text/plain" },
      },
      paste = {
        ["+"] = { "wl-paste", "--no-newline" },
        ["*"] = { "wl-paste", "--no-newline", "--primary" },
      },
      cache_enabled = 1,
    }
  else
    fail()
  end
end)
