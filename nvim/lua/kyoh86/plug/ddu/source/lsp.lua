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

    require("kyoh86.lib.scheme").onSchemeChanged(function(colors_name)
      kyoh86.ensure(colors_name, function(m)
        vim.api.nvim_set_hl(0, "DduLspDefinitionMethodDef", { fg = m.colors.red, bold = true })
        vim.api.nvim_set_hl(0, "DduLspDefinitionMethodType", { fg = m.colors.blue, bold = true })
        vim.api.nvim_set_hl(0, "DduLspDefinitionMethodDecl", { fg = m.colors.green, bold = true })
        vim.api.nvim_set_hl(0, "DduLspDefinitionMethodImpl", { fg = m.colors.magenta, bold = true })
      end)
    end, true)

    local custom_preview = function(args)
      if #args.items ~= 1 then
        vim.notify("invalid action: it can show only one file at once", vim.log.levels.WARN, {})
        return 1
      end
      local action = args.items[1].action
      vim.cmd(string.format("pedit +%d %s", action.lnum, action.path))
      return 0
    end
    vim.fn["ddu#custom#action"]("kind", "lsp", "custom:preview", custom_preview)
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
      start = {
        key = "<leader>ld",
        desc = "定義",
      },
      filelike = true,
      localmap = {
        ["<leader>p"] = { action = "itemAction", params = { name = "custom:preview" } },
      },
    })

    helper.setup("lsp-code-actions", {
      sources = { { name = "lsp_codeAction" } },
      kindOptions = {
        lsp = {
          defaultAction = "open",
        },
        lsp_codeAction = {
          defaultAction = "apply",
        },
      },
    }, {
      start = {
        modes = { "n", "x" },
        key = "<leader>lca",
        desc = "コードアクション",
      },
    })

    helper.setup("lsp-references", {
      sources = { { name = "lsp_references" } },
    }, {
      start = {
        key = "<leader>lfr",
        desc = "参照",
      },
      filelike = true,
    })

    helper.setup("lsp-symbols", {
      sources = { { name = "lsp_workspaceSymbol" } },
      sourceOptions = { lsp = { volatile = true } },
    }, {
      start = {
        key = "<leader>lfw",
        desc = "シンボル",
      },
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
        },
      },
    }, {
      start = {
        key = "<leader>lch",
        desc = "呼び出し階層",
      },
      filelike = true,
    })
  end,
}
return spec
