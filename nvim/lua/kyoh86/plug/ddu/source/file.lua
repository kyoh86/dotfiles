local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "matsui54/ddu-source-file_external",
  config = function()
    helper.start_by("<leader>ff", "file-hide", {
      sources = { {
        name = "file_external",
        params = { cmd = { "rg", "--files", "--color", "never" } },
      } },
    })

    helper.start_by("<leader>faf", "file-all", {
      sources = { { name = "file_rec" } },
    })

    helper.map_for_file("file-hide")
    helper.map_for_file("file-all")

    -- setup source for nvim-configs
    helper.start_by("<leader><leader>c", "nvim-config", { sources = { { name = "file_rec", options = { path = vim.env.XDG_CONFIG_HOME } } } })
    helper.map_for_file("nvim-config")
  end,
  dependencies = { "Shougo/ddu.vim", "Shougo/ddu-kind-file", "Shougo/ddu-source-file_rec" },
}
return spec
