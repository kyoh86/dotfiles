local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kuuote/ddu-source-git_status",
  dependencies = { "Shougo/ddu.vim" },
  config = function()
    helper.map_start("<leader>fgs", "git-status", {
      sources = { { name = "git_status" } },
      kindOptions = {
        git_status = {
          defaultAction = "open",
        },
      },
    })
    helper.map_ff("git-status", {
      ["<leader>x"] = { action_name = "itemAction", params = { name = "open", params = { command = "new" } } },
      ["<leader>v"] = { action_name = "itemAction", params = { name = "open", params = { command = "vnew" } } },
    })
  end,
}
return spec
