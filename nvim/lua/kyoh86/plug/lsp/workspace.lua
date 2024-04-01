local M = {}
local ft = require("kyoh86.plug.lsp.filetype")

local function detect_files()
  return vim.fn.split(vim.fn.system("git ls-files"), "\n")
end

local function populate_file(client, path)
  local filetype = ft.get(path)
  if client.config.filetypes == nil or not vim.tbl_contains(client.config.filetypes, filetype) then
    return
  end
  local params = {
    textDocument = {
      uri = vim.uri_from_fname(path),
      version = 0,
      text = vim.fn.join(vim.fn.readfile(path), "\n"),
      languageId = filetype,
    },
  }
  client.notify("textDocument/didOpen", params)
end

function M.populate(client, options)
  options = vim.tbl_deep_extend("force", { detect_files = detect_files }, options or {})

  if not vim.tbl_get(client.server_capabilities, "textDocumentSync", "openClose") then
    return
  end

  local files = options.detect_files()

  files = vim.tbl_filter(function(path)
    return vim.fn.filereadable(path) == 1
  end, files)

  files = vim.tbl_map(function(path)
    return vim.fn.fnamemodify(path, ":p")
  end, files)

  for _, path in ipairs(files) do
    populate_file(client, path)
  end
end

return M
