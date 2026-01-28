--- Attach時の設定
return function(args)
  local bufnr = args.buf
  local client = vim.lsp.get_client_by_id(args.data.client_id)
  if client == nil then
    return
  end

  if client.server_capabilities.completionProvider ~= nil then
    vim.lsp.completion.enable(true, client.id, bufnr, {
      convert = function(item)
        return { abbr = item.label:gsub("%b()", "") }
      end,
    })
    vim.opt_local.completeopt = "menu,menuone,noselect,noinsert,fuzzy"
  end
  -- ファイル保存時に自動でフォーマットする
  -- vtslsがassignされている場合はvtsls、efmがアサインされている場合はefm
  vim.api.nvim_create_autocmd("BufWritePre", {
    desc = "ファイル保存時に自動でフォーマットする",
    group = vim.api.nvim_create_augroup(string.format("kyoh86-plug-lsp-format-buf-%d", bufnr), { clear = true }),
    buffer = bufnr,
    callback = function()
      require("kyoh86.plug.lsp.format")(bufnr)
    end,
  })

  if client.server_capabilities.inlayHintProvider ~= nil then
    vim.b.kyoh86_plug_lsp_inlay_hint_enabled = true
  end

  client.server_capabilities.semanticTokensProvider = nil

  --- Attach時の設定: 特定のBuffer名と特定のClient名の組み合わせで、LSP Clientを無効化する
  --- バッファ名のパターンをPlain textとして扱いたい（パターンではなくLiteral matchとする）場合はplain = trueを指定する
  ---@type {eslint: table[], [string]: nil}
  local disabled_clients = {
    eslint = { {
      name = "upmind-inc/upmind-server",
      plain = true,
    } },
  }
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local lsp_local_disable = disabled_clients[client.name]
  if lsp_local_disable ~= nil then
    for _, v in pairs(lsp_local_disable) do
      if string.find(bufname, v.name, 1, v.plain) ~= nil then
        client:stop()
        break
      end
    end
  end
end
