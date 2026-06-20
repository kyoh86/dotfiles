return {
  -- Lua - Vim script境界を越えられる形に整えたLSP Client情報を返す
  -- 一部フィールドが大きすぎてデバッグ等に面倒くさいため、実用してない限りフィールド数は絞っている
  get_convertible_clients = function()
    return vim.tbl_map(function(client)
      local trimmed = {
        attached_buffers = {},
        exit_timeout = client.exit_timeout,
        id = client.id,
        name = client.name,
        offset_encoding = client.offset_encoding,
      }
      if vim.tbl_get(client, "initialized") then
        trimmed.initialized = true
      end
      local root = vim.tbl_get(client, "root_dir")
      if root then
        trimmed.root_dir = root
      end
      for k, v in pairs(client.attached_buffers) do
        trimmed.attached_buffers[string.format("%d", k)] = v
      end
      return trimmed
    end, vim.lsp.get_clients())
  end,
}
