local group = vim.api.nvim_create_augroup("kyoh86-plug-denols-deno-docs", { clear = true })
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = group,
  pattern = { "deno:/*" },
  callback = function()
    vim.bo.bufhidden = "wipe"
  end,
})
return {
  settings = {
    lint = true,
    unstable = false,
    suggest = {
      completeFunctionCalls = true,
      names = true,
      paths = true,
      autoImports = true,
      imports = {
        autoDiscover = true,
        hosts = vim.empty_dict(),
      },
    },
  },
  single_file_support = false,
  ---@param bufnr number
  ---@param callback fun(root_dir?: string)
  root_dir = function(bufnr, callback)
    local path = vim.fn.fnamemodify(vim.fn.bufname(bufnr), ":p:h")
    local marker = require("climbdir.marker")
    local found = require("climbdir").climb(path, marker.one_of(marker.has_readable_file("deno.json"), marker.has_readable_file("deno.jsonc"), marker.has_directory("denops")), {})
    if found then
      vim.b[vim.fn.bufnr()].deno_deps_candidate = found .. "/deps.ts"
    end
    callback(found)
  end,
}
