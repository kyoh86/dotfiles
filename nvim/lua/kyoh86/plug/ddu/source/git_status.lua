local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "kuuote/ddu-source-git_status",
  dependencies = { "Shougo/ddu.vim" },
  config = function()
    local name = "git-status"
    helper.map_start("<leader>fgs", {
      name = name,
      sources = { { name = "git_status" } },
      kindOptions = {
        git_status = {
          defaultAction = "open",
        },
      },
    })
    helper.map_ff(name, {
      ["<leader>x"] = { action_name = "itemAction", params = { name = "open", params = { command = "new" } } },
      ["<leader>v"] = { action_name = "itemAction", params = { name = "open", params = { command = "vnew" } } },
    })
  end,
}
return spec
