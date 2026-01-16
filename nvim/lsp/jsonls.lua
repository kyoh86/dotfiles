local ok, schemastore = pcall(require, "schemastore")

local schema_path = vim.fn.expand("~/Projects/github.com/kyoh86/nvim-snap/snapcase-example/snapcase.schema.json")
local schemas = {
  {
    description = "nvim-snap case",
    fileMatch = { "snapcase.json" },
    url = vim.uri_from_fname(schema_path),
  },
}

if ok then
  schemas = vim.list_extend(schemas, schemastore.json.schemas())
end

return {
  settings = {
    json = {
      schemas = schemas,
      validate = { enable = true },
    },
  },
}
