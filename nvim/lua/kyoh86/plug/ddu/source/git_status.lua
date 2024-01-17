local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kuuote/ddu-source-git_status",
  dependencies = { "ddu.vim" },
  config = helper.setup_func("git-status", {
    sources = { { name = "git_status" } },
    kindOptions = {
      git_status = {
        defaultAction = "open",
      },
    },
  }, {
    start = {
      key = "<leader>fgs",
      desc = "Git Status",
    },
    localmap = {
      ["<leader>x"] = { action = "itemAction", params = { name = "open", params = { command = "new" } } },
      ["<leader>v"] = { action = "itemAction", params = { name = "open", params = { command = "vnew" } } },
    },
  }),
}
return spec
