local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kuuote/ddu-source-git_status",
  dependencies = { "ddu.vim" },
  config = function()
    helper.setup("git-status", {
      sources = { { name = "git_status" } },
      kindOptions = {
        git_status = {
          defaultAction = "open",
        },
      },
    }, {
      startkey = "<leader>fgs",
      localmap = {
        ["<leader>x"] = { action = "itemAction", params = { name = "open", params = { command = "new" } } },
        ["<leader>v"] = { action = "itemAction", params = { name = "open", params = { command = "vnew" } } },
      },
    })
  end,
}
return spec
