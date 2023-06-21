local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "uga-rosa/ddu-source-lsp",
  config = function()
    vim.fa.ddu.custom.patch_global({ kindOptions = {
      lsp = {
        defaultAction = "open",
      },
      lsp_codeAction = {
        defaultAction = "apply",
      },
    } })

    helper.start_by("<leader>fld", "lsp_definition", {
      sources = { { name = "lsp_definition" } },
    })
    helper.map_for_file("lsp_definition")

    helper.start_by("<leader>flr", "lsp_references", {
      sources = { { name = "lsp_references" } },
    })
    helper.map_for_file("lsp_references")

    helper.start_by("<leader>flw", "lsp_workspaceSymbol", {
      sources = { { name = "lsp_workspaceSymbol" } },
      sourceOptions = { lsp = { volatile = true } },
    })
    helper.map_for_file("lsp_workspaceSymbol")

    helper.start_by("<leader>flc", "lsp_callHierarchy", {
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
    helper.map_for_file("lsp_callHierarchy")

    vim.keymap.set({ "n", "x" }, "<leader>fla", "<cmd>call ddu#start({'sources': [{'name': 'lsp_codeAction'}]})<cr>", {
      remap = false,
      desc = "Start ddu source: lsp_codeAction",
    })
  end,
  dependencies = { { "Shougo/ddu.vim" } },
}
return spec
