vim.api.nvim_create_autocmd("DirChanged", {
  once = true, -- 離脱に「実行前の状態に戻す」ことが難しいので、onceを付けて「最初の移動」で検出するのみに留める
  callback = function(args)
    for _, file in ipairs({ ".nvim.lua", ".nvimrc", ".exrc" }) do
      local contents = vim.secure.read(string.format("%s/%s", args.file, file)) --[[@as string|true|nil]]
      if contents == true then
        -- ディレクトリは無視
      elseif contents ~= nil then
        if vim.endswith(file, ".lua") then
          assert(loadstring(contents))()
        else
          vim.cmd(contents)
        end
        break
      end
    end
  end,
})
