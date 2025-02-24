return {
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
  root_dir = function(path)
    local marker = require("climbdir.marker")
    local has_npm = marker.one_of(marker.has_readable_file("package.json"), marker.has_directory("node_modules"))
    local has_deno = marker.one_of(marker.has_readable_file("deno.json"), marker.has_readable_file("deno.jsonc"), marker.has_directory("denops"))
    local positive = marker.all_of(has_npm, marker.not_of(has_deno))
    return require("climbdir").climb(path, positive, {
      halt = has_deno,
    })
  end,
  single_file_support = false,
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },
}
