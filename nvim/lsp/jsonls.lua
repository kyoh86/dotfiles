return {
  on_init = function(client)
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
    client.config.settings = vim.tbl_deep_extend("force", client.config.settings or {}, {
      json = {
        schemas = schemas,
        validate = { enable = true },
      },
    })
  end,
}
