local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = { {
  "lambdalisue/mr.vim",
}, {
  "kuuote/ddu-source-mr",
  dependencies = { "ddu.vim", "ddu-kind-file", "mr.vim" },
  config = function()
    helper.setup("mrw", {
      sources = { { name = "mr", params = { kind = "mrw" } } },
    }, {
      start = {
        key = "<leader>fmw",
        desc = "最近書いたファイル",
      },
      filelike = true,
    })
    helper.setup("mrr", {
      sources = { { name = "mr", params = { kind = "mrr" } } },
      kindOptions = {
        file = {
          defaultAction = "cd",
        },
      },
    }, {
      start = {
        key = "<leader>fmr",
        desc = "最近開いたリポジトリ",
      },
      filelike = true,
    })
    helper.setup("mru", {
      sources = { { name = "mr", params = { kind = "mru" } } },
    }, {
      start = {
        key = "<leader>fmu",
        desc = "最近開いたファイル",
      },
      filelike = true,
    })
  end,
} }
return spec
