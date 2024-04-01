local M = {}
local ft = require("kyoh86.plug.lsp.filetype")

local function files()
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
  options = vim.tbl_deep_extend("force", { files = files }, options or {})

  if not vim.tbl_get(client.server_capabilities, "textDocumentSync", "openClose") then
    return
  end

  local workspace_files = options.files()

  for _, path in ipairs(workspace_files) do
    populate_file(client, path)
  end
end

return M
