-- Convenience runner for busted UI tests.
local script = vim.fs.normalize(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p"))
local ui_dir = vim.fs.dirname(script)
local test_root = vim.fs.dirname(ui_dir)
_G.arg = { "--directory", test_root, ui_dir }
require("busted.runner")({
  standalone = false,
  output = "plainTerminal",
})
