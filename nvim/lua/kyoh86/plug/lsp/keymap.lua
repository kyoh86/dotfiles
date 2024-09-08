return function()
  local f = require("kyoh86.lib.func")
  local setmap = function(modes, lhr, rhr, desc)
    vim.keymap.set(modes, lhr, rhr, { remap = false, silent = true, desc = desc })
  end
  -- show / edit actions
  setmap("n", "<leader>lii", function()
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.b[bufnr].kyoh86_plug_lsp_inlay_hint_enabled == true then
      vim.lsp.buf.inlay_hint(bufnr, nil)
    end
  end, "inlay-hintを表示する")
  setmap("n", "<leader>lih", vim.lsp.buf.hover, "カーソル下のシンボルの情報を表示する")
  setmap("n", "<leader>lis", vim.lsp.buf.signature_help, "カーソル下のシンボルのシグネチャを表示する")
  setmap("n", "<leader>lr", vim.lsp.buf.rename, "カーソル下のシンボルをリネームする")
  setmap("n", "]l", f.bind_all(vim.diagnostic.jump, { count = 1 }), "次のDiagnosticに移動する")
  setmap("n", "[l", f.bind_all(vim.diagnostic.jump, { count = -1 }), "前のDiagnosticに移動する")

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
  end, "コードアクションを選択する")

  setmap("n", "<leader>lqr", vim.lsp.buf.references, "カーソル下のシンボルの参照元をQuickfixに表示する")
  setmap("n", "<leader>lqs", vim.lsp.buf.document_symbol, "現在のバッファのシンボルをQuickfixに表示する")
  setmap("n", "<leader>lqS", vim.lsp.buf.workspace_symbol, "現在のワークスペースのシンボルをQuickfixに表示する")
  setmap("n", "<leader>lqc", vim.lsp.buf.incoming_calls, "カーソル下のシンボルの呼び出し元をQuickfixに表示する")
  setmap("n", "<leader>lqC", vim.lsp.buf.outgoing_calls, "カーソル下のシンボルの呼び出し先をQuickfixに表示する")
  setmap("n", "<leader>lqd", vim.diagnostic.setqflist, "現在のバッファのDiagnosticをQuickfixに表示する")
  setmap("n", "<leader>lqD", function()
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = vim.fn.bufnr() })) do
      require("kyoh86.plug.lsp.workspace").populate(client)
    end
    vim.diagnostic.setqflist()
  end, "現在のWorkspaceのDiagnosticをQuickfixに表示する")

  -- show diagnostics
  setmap("n", "<leader>lid", vim.diagnostic.open_float, "show diagnostics in a floating window")
end
