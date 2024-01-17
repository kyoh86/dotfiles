local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  {
    "Shougo/ddu-source-file_rec",
    dependencies = { "ddu.vim", "ddu-kind-file" },
    config = function()
      helper.setup("file-all", {
        sources = { { name = "file_rec" } },
      }, {
        start = {
          key = "<leader>faf",
          desc = "すべてのファイル",
        },
        filelike = true,
      })
      -- setup source for nvim-configs
      helper.setup("nvim-config", {
        sources = { { name = "file_rec", options = { path = vim.env.XDG_CONFIG_HOME } } },
      }, {
        start = {
          key = "<leader><leader>c",
          desc = "nvim設定ファイル",
        },
        filelike = true,
      })
    end,
  },
  {
    "matsui54/ddu-source-file_external",
    dependencies = { "ddu.vim", "ddu-kind-file" },
    config = helper.setup_func("file-hide", {
      sources = { {
        name = "file_external",
        params = { cmd = { "rg", "--files", "--color", "never" } },
      } },
    }, {
      start = {
        key = "<leader>ff",
        desc = "ファイル",
      },
      filelike = true,
    }),
  },
}
return spec
