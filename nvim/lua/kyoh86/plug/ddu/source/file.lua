local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "matsui54/ddu-source-file_external",
  dependencies = { "Shougo/ddu.vim", "Shougo/ddu-kind-file", "Shougo/ddu-source-file_rec" },
  config = function()
    helper.map_start("<leader>ff", "file-hide", {
      sources = { {
        name = "file_external",
        params = { cmd = { "rg", "--files", "--color", "never" } },
      } },
    })

    helper.map_start("<leader>faf", "file-all", {
      sources = { { name = "file_rec" } },
    })

    helper.map_ff_file("file-hide")
    helper.map_ff_file("file-all")

    -- setup source for nvim-configs
    helper.map_start("<leader><leader>c", "nvim-config", { sources = { { name = "file_rec", options = { path = vim.env.XDG_CONFIG_HOME } } } })
    helper.map_ff_file("nvim-config")
  end,
}
return spec
