---@type vim.lsp.Config
local config = {
  settings = {
    typescript = {
      importModuleSpecifier = "relative",
      inlayHints = {
        parameterNames = {
          enabled = "literals",
          suppressWhenArgumentMatchesName = true,
        },
        parameterTypes = { enabled = true },
        variableTypes = { enabled = false },
        propertyDeclarationTypes = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        enumMemberValues = { enabled = true },
      },
    },
  },
  on_attach = function(client, bufnr)
    vim.lsp.completion.enable(true, client.id, bufnr, {
      convert = function(item)
        return { abbr = item.label:gsub("%b()", "") }
      end,
    })
  end,
  ---@param bufnr number
  ---@param callback fun(root_dir?: string)
  root_dir = function(bufnr, callback)
    local marker = require("climbdir.marker")
    local path = vim.fn.fnamemodify(vim.fn.bufname(bufnr), ":p:h")
    local has_npm = marker.one_of(marker.has_readable_file("package.json"), marker.has_directory("node_modules"))
    local has_deno = marker.one_of(marker.has_readable_file("deno.json"), marker.has_readable_file("deno.jsonc"), marker.has_directory("denops"))
    local positive = marker.all_of(has_npm, marker.not_of(has_deno))
    local found = require("climbdir").climb(path, positive, {
      halt = has_deno,
    })
    if found then
      callback(found)
    end
  end,
}
return config
