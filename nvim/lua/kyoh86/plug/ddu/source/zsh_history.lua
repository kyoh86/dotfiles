local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kyoh86/ddc-source-zsh-history", -- It also contains the source of the ddu plugin.
  dependencies = { "ddu.vim", "lazy.nvim" },
  config = function()
    helper.setup("zsh_history", {
      sources = { {
        name = "zsh_history",
        options = {
          matchers = { "matcher_fzf" },
          sorters = { "sorter_fzf" },
        },
      } },
      kindOptions = { zsh_history = { defaultAction = "append" } },
    }, {
      start = { {
        modes = "t",
        key = "<c-x>y",
        desc = "ZSH History",
      }, {
        modes = "t",
        key = "<c-x><c-y>",
        desc = "ZSH History",
      }, {
        modes = "t",
        key = "<c-r>",
        desc = "ZSH History",
      } },
    })
  end,
}
return spec
