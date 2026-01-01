return function()
  local f = require("kyoh86.lib.func")
  local setmap = function(modes, lhr, rhr, desc)
    vim.keymap.set(modes, lhr, rhr, { remap = false, silent = true, desc = desc })
  end
  -- show / edit actions
  setmap("n", "<leader>lii", function()
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.b[bufnr].kyoh86_plug_lsp_inlay_hint_enabled == true then
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
    end
  end, "inlay-hintを表示する")
  setmap("n", "<leader>lih", f.bind_all(vim.lsp.buf.hover, { border = "single" }), "カーソル下のシンボルの情報を表示する")
  setmap("n", "<leader>lis", f.bind_all(vim.lsp.buf.signature_help, { border = "single" }), "カーソル下のシンボルのシグネチャを表示する")
  setmap("n", "<leader>lr", vim.lsp.buf.rename, "カーソル下のシンボルをリネームする")

  setmap("i", "<c-space>", function()
    vim.lsp.completion.get()
  end, "補完する")
  -- see: /usr/local/share/nvim/runtime/lua/vim/_defaults.lua
  vim.keymap.set("n", "<leader>jdN", f.bind_all(vim.diagnostic.jump, { count = math.huge, wrap = false }), { desc = "Jump to the last diagnostic in the current buffer" })
  vim.keymap.set("n", "<leader>jdn", f.bind_all(vim.diagnostic.jump, { count = vim.v.count1 }), { desc = "Jump to the next diagnostic in the current buffer" })
  vim.keymap.set("n", "<leader>jdp", f.bind_all(vim.diagnostic.jump, { count = -vim.v.count1 }), { desc = "Jump to the previous diagnostic in the current buffer" })
  vim.keymap.set("n", "<leader>jdP", f.bind_all(vim.diagnostic.jump, { count = -math.huge, wrap = false }), { desc = "Jump to the first diagnostic in the current buffer" })

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
  setmap("n", "<leader>lid", function()
    local new_config = not vim.diagnostic.config().virtual_lines
    vim.diagnostic.config({ virtual_lines = new_config })
  end, "Toggle showing diagnostics in virtual lines")
  setmap("n", "<leader>lif", vim.diagnostic.open_float, "show diagnostics in a floating window")
end
