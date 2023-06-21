local conditions = require("heirline.conditions")
local Diagnostics = {
  condition = conditions.has_diagnostics,

  static = {
    error_icon = " \u{EA87}", -- [[ 1 ]]
    warn_icon = " \u{EA6C}", -- [[ 1 ]]
    info_icon = " \u{EA74}", -- [[ 1 ]]
    hint_icon = " \u{F0EB}", -- [[ 1 ]]
  },

  init = function(self)
    self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
    self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
    self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
    self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
  end,

  update = { "DiagnosticChanged", "BufEnter" },

  {
    provider = function(self)
      -- 0 is just another output, we can decide to print it or not!
      return self.errors > 0 and (self.error_icon .. self.errors .. " ")
    end,
    hl = { bg = "red", fg = "lightwhite" },
  },
  {
    provider = function(self)
      return self.warnings > 0 and (self.warn_icon .. self.warnings .. " ")
    end,
    hl = { bg = "yellow", fg = "black" },
  },
  {
    provider = function(self)
      return self.info > 0 and (self.info_icon .. self.info .. " ")
    end,
    hl = { bg = "blue", fg = "black" },
  },
  {
    provider = function(self)
      return self.hints > 0 and (self.hint_icon .. self.hints)
    end,
    hl = { bg = "grayscale3", fg = "lightwhite" },
  },
}
return Diagnostics
