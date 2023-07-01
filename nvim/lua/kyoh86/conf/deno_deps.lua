--- Denoのdeps.tsを開いておくことで、LSPなどによる補完の助けとする
local function open_deno_deps(e)
  local buf = e.buf
  local path = vim.b[buf].deno_deps_candidate
  if not path then
    return
  end
  if vim.fn.bufnr(path) >= 0 then
    -- in case of that deps.ts is opened already
    return
  end
  if vim.fn.filereadable(path) == 0 then
    -- in case of that deps.ts does not exist
    return
  end
  -- open deps.ts in background (floatwin)
  kyoh86.ensure("backgroundfile", function(m)
    m.open(path)
  end)
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("kyoh86-conf-open-deno-deps", {}),
  pattern = "typescript",
  callback = open_deno_deps,
  nested = true,
})

return {
  { "kyoh86/backgroundfile.nvim" },
}
