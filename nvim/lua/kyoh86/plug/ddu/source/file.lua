local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  {
    "Shougo/ddu-source-file",
    dependencies = { "ddu.vim", "ddu-kind-file", "ddu-filter-sorter_treefirst", "ddu-filter-sorter_alpha" },
    config = function()
      helper.setup("file-tree", {
        sources = { {
          name = "file",
          options = {
            sorters = { "sorter_alpha", "sorter_treefirst" },
          },
        } },
      }, {
        start = {
          key = "<leader>fft",
          desc = "すべてのファイル（ツリー）",
        },
        filelike = true,
      })
    end,
  },
  {
    "Shougo/ddu-source-file_rec",
    dependencies = { "ddu.vim", "ddu-kind-file" },
    config = function()
      helper.setup("file-rec", {
        sources = { { name = "file_rec" } },
      }, {
        start = {
          key = "<leader>ffr",
          desc = "すべてのファイル（再帰）",
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
        key = "<leader>fff",
        desc = "管理対象ファイル",
      },
      filelike = true,
    }),
  },
}
return spec
