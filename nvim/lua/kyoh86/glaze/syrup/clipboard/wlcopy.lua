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
