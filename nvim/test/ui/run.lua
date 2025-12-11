-- Convenience runner for busted UI tests.
_G.arg = _G.arg or { "--directory", ".", "nvim/test/ui" }
require("busted.runner")({ standalone = false, output = "plainTerminal" })
