local schemas = require("schemastore").json.schemas()
table.insert(schemas, {
  description = "JSON schema for VSCode Code Snippets",
  fileMatch = { "nvim/vsnip/*.json" },
  url = "https://raw.githubusercontent.com/Yash-Singh1/vscode-snippets-json-schema/main/schema.json",
})
table.insert(schemas, {
  description = "Google Tag Manager",
  fileMatch = "GTM-*_workspace*.json",
  url = vim.fn.stdpath("config") .. "/schema/gtm.json",
})
return {
  settings = {
    json = {
      schemas = schemas,
      validate = { enable = true },
    },
  },
}
