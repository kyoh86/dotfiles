vim.opt.clipboard = "unnamed"
vim.g.clipboard = {
  name = "win32yank-wsl",
  copy = {
    ["+"] = "win32yank.exe -i --crlf",
    ["*"] = function(lines, regtype)
      vim.g["kyoh86_clip_aster"] = { lines, regtype }
    end,
  },
  paste = {
    ["+"] = "win32yank.exe -o --lf",
    ["*"] = function(lines, regtype)
      return vim.g["kyoh86_clip_aster"] or {}
    end,
  },
  cache_enabled = 1,
}
