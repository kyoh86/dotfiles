local func = require("kyoh86.lib.func")

return function(diagnosis_config)
  local setmap = function(modes, lhr, rhr, desc)
    vim.keymap.set(modes, lhr, rhr, { remap = false, silent = true, desc = desc })
  end
  -- show / edit actions
  setmap("n", "<leader>li", function()
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.b[bufnr].kyoh86_plug_lsp_inlay_hint_enabled == true then
      vim.lsp.buf.inlay_hint(bufnr, nil)
    end
  end, "displays inlay hints")
  setmap("n", "<leader>lh", vim.lsp.buf.hover, "displays hover information about the symbol under the cursor in a floating window")
  setmap("n", "<leader>ls", vim.lsp.buf.signature_help, "displays signature information about the symbol under the cursor in a floating window")
  setmap("n", "<leader>lr", vim.lsp.buf.rename, "renames all references to the symbol under the cursor")
  setmap("n", "]l", vim.diagnostic.goto_next, "move to the next diagnostic")
  setmap("n", "[l", vim.diagnostic.goto_prev, "move to the previous diagnostic in the current buffer")

  local function range_from_selection(mode)
    -- workaround for https://github.com/neovim/neovim/issues/22629
    local start = vim.fn.getpos("v")
    local end_ = vim.fn.getpos(".")
    if start == nil or end_ == nil then
      return nil
    end
    local start_row = start[2]
    local start_col = start[3]
    local end_row = end_[2]
    local end_col = end_[3]

    if start_row == end_row and end_col < start_col then
      end_col, start_col = start_col, end_col
    elseif end_row < start_row then
      start_row, end_row = end_row, start_row
      start_col, end_col = end_col, start_col
    end
    if mode == "V" then
      -- select whole line in the selection (in linewise-visual mode)
      start_col = 1
      local lines = vim.api.nvim_buf_get_lines(0, end_row - 1, end_row, true)
      end_col = #lines[1]
    end
    return {
      start = { start_row, start_col - 1 },
      ["end"] = { end_row, end_col - 1 },
    }
  end
  setmap({ "n", "v" }, "<leader>lca", function()
    local range = range_from_selection(vim.api.nvim_get_mode().mode)
    if range == nil then
      return
    end
    vim.lsp.buf.code_action({ range = range })
  end, "selects a code action available at the current cursor position")

  -- listup actions
  local function wrap_on_list(f)
    return func.bind(f, {
      on_list = function(options)
        vim.fn.setqflist({}, " ", options)
        vim.cmd.copen()
      end,
    })
  end

  setmap("n", "<leader>lf", vim.lsp.buf.definition, "jumps to the definition of the symbol under the cursor")
  setmap("n", "<leader>ld", vim.lsp.buf.declaration, "jumps to the declaration of the symbol under the cursor")
  setmap("n", "<leader>ltf", vim.lsp.buf.type_definition, "jumps to the type definition of the symbol under the cursor")
  setmap("n", "<leader>llr", vim.lsp.buf.references, "lists all the references to the symbol under the cursor in the quickfix window")
  setmap("n", "<leader>lls", vim.lsp.buf.document_symbol, "lists all symbols in the current buffer in the quickfix window")
  setmap("n", "<leader>llS", vim.lsp.buf.workspace_symbol, "lists all symbols in the current workspace in the quickfix window")
  setmap("n", "<leader>llc", vim.lsp.buf.incoming_calls, "lists all the call sites of the symbol under the cursor in the quickfix window")
  setmap("n", "<leader>llC", vim.lsp.buf.outgoing_calls, "lists all the items that are called by the symbol under the cursor in the quickfix window")
  setmap("n", "<leader>lld", vim.diagnostic.setqflist, "add all diagnostics to the quickfix list")

  -- show diagnostics
  setmap("n", "<leader>lll", func.bind_all(vim.diagnostic.open_float, diagnosis_config), "show diagnostics in a floating window")
end
