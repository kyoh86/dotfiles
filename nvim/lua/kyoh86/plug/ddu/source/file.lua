local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "matsui54/ddu-source-file_external",
  dependencies = { "Shougo/ddu.vim", "Shougo/ddu-kind-file", "Shougo/ddu-source-file_rec" },
  config = function()
    helper.setup("file-hide", {
      sources = { {
        name = "file_external",
        params = { cmd = { "rg", "--files", "--color", "never" } },
      } },
    }, {
      startkey = "<leader>ff",
      filelike = true,
    })

    helper.setup("file-all", {
      sources = { { name = "file_rec" } },
    }, {
      startkey = "<leader>faf",
      filelike = true,
    })

    -- setup source for nvim-configs
    helper.setup("nvim-config", {
      sources = { { name = "file_rec", options = { path = vim.env.XDG_CONFIG_HOME } } },
    }, {
      startkey = "<leader><leader>c",
      filelike = true,
    })
  end,
}
return spec
