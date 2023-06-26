local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "uga-rosa/ddu-source-lsp",
  dependencies = { { "Shougo/ddu.vim", "Shougo/ddu-kind-file" } },
  config = function()
    kyoh86.fa.ddu.custom.patch_global({ kindOptions = {
      lsp = {
        defaultAction = "open",
      },
    } })

    helper.map_start("<leader>fld", "lsp_definition", {
      sources = { { name = "lsp_definition" } },
    })
    helper.map_ff_file("lsp_definition")

    helper.map_start("<leader>flr", "lsp_references", {
      sources = { { name = "lsp_references" } },
    })
    helper.map_ff_file("lsp_references")

    helper.map_start("<leader>flw", "lsp_workspaceSymbol", {
      sources = { { name = "lsp_workspaceSymbol" } },
      sourceOptions = { lsp = { volatile = true } },
    })
    helper.map_ff_file("lsp_workspaceSymbol")

    helper.map_start("<leader>flc", "lsp_callHierarchy", {
      sources = { {
        name = "lsp_callHierarchy",
        params = {
          method = "callHierarchy/outgoingCalls",
        },
      } },
      sourceOptions = { lsp = { volatile = true } },
      uiParams = {
        ff = {
          displayTree = true,
          startFilter = false,
        },
      },
    })
    helper.map_ff_file("lsp_callHierarchy")
  end,
}
return spec
