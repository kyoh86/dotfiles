local envar = require("kyoh86.lib.envar")
envar.REACT_EDITOR = table.concat({ vim.v.progpath, "--server", vim.v.servername, "--remote" }, " ")
