return {
  init_options = {
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
  root_dir = function(path)
    local marker = require("climbdir.marker")
    local found = require("climbdir").climb(path, marker.one_of(marker.has_readable_file("deno.json"), marker.has_readable_file("deno.jsonc"), marker.has_directory("denops")), {
      halt = marker.one_of(marker.has_readable_file("package.json"), marker.has_directory("node_modules")),
    })
    if found then
      vim.b[vim.fn.bufnr()].deno_deps_candidate = found .. "/deps.ts"
    end
    return found
  end,
}
