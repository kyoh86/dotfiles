local helper = require("kyoh86.plug.ddu.helper")

---@type LazySpec
local spec = {
  "uga-rosa/ddu-source-lsp",
  dependencies = { "ddu.vim", "ddu-kind-file" },
  config = function()
    vim.fn["ddu#custom#patch_global"]({ kindOptions = {
      lsp = {
        defaultAction = "open",
      },
    } })

    vim.fn["ddu#custom#patch_global"]({
      sourceOptions = {
        lsp_definition = {
          converters = { { name = "converter_custom_lsp_definitions" } },
        },
      },
    })

    kyoh86.ensure("momiji", function(m)
      vim.api.nvim_set_hl(0, "DduLspDefinitionMethodDef", { fg = m.colors.red, bold = true })
      vim.api.nvim_set_hl(0, "DduLspDefinitionMethodType", { fg = m.colors.blue, bold = true })
      vim.api.nvim_set_hl(0, "DduLspDefinitionMethodDecl", { fg = m.colors.green, bold = true })
      vim.api.nvim_set_hl(0, "DduLspDefinitionMethodImpl", { fg = m.colors.magenta, bold = true })
    end)

    helper.setup("lsp-definition", {
      sync = true,
      sources = {
        { name = "lsp_definition", params = { method = "textDocument/definition" } },
        { name = "lsp_definition", params = { method = "textDocument/typeDefinition" } },
        { name = "lsp_definition", params = { method = "textDocument/declaration" } },
        { name = "lsp_definition", params = { method = "textDocument/implementation" } },
      },
      uiParams = {
        ff = {
          immediateAction = "open",
        },
      },
    }, {
      startkey = { "<leader>fld", "<leader>ld" },
      filelike = true,
    })

    helper.setup("lsp-references", {
      sources = { { name = "lsp_references" } },
    }, {
      startkey = "<leader>flr",
      filelike = true,
    })

    helper.setup("lsp-symbols", {
      sources = { { name = "lsp_workspaceSymbol" } },
      sourceOptions = { lsp = { volatile = true } },
    }, {
      startkey = "<leader>flw",
      filelike = true,
    })

    helper.setup("lsp-call-hierarchy", {
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
    }, {
      startkey = "<leader>flc",
      filelike = true,
    })
  end,
}
return spec
