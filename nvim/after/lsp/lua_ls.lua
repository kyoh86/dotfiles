local function first(list)
  if list == nil or #list == 0 then
    return nil
  end
  return list[1]
end

---@type vim.lsp.Config
local config = {
  settings = {
    Lua = {
      hint = {
        -- Enable inlay hints
        enable = true,
      },
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = "LuaJIT",
        pathStrict = true,
        path = { "?.lua", "?/init.lua" },
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        checkThirdParty = false,
        library = {
          vim.fn.expand("~/.luarocks/share/lua/5.3"),
          "/usr/share/lua/5.3",
          vim.fn.expand("~/Projects/github.com/kyoh86/gogh/lua"),
        },
      },
      completion = {
        callSnippet = "Replace",
      },
      -- Do not send telemetry data containing a randomized but unique identifier
      telemetry = {
        enable = false,
      },
      format = {
        enable = false,
      },
    },
  },
  on_init = function(client)
    local folder = first(client.workspace_folders)
    if folder == nil then
      return
    end
    if folder.name ~= vim.env.DOTFILES .. "/nvim" then
      return
    end
    local plugins = require("lazy.core.config").plugins
    local paths = vim.list_extend({
      vim.fs.joinpath(vim.fn.stdpath("config") --[[@as string]], "lua"),
      vim.fs.joinpath(vim.env.VIMRUNTIME, "lua"),
      "${3rd}/luv/library",
      "${3rd}/busted/library",
      "${3rd}/luassert/library",
    }, vim.tbl_get(client.config, "settings", "Lua", "workspace", "library") or {})
    for _, plugin in pairs(plugins) do
      local plugin_dir = vim.fs.joinpath(plugin.dir, "lua")
      if vim.fn.isdirectory(plugin_dir) then
        table.insert(paths, plugin_dir)
      end
    end
    local settings = vim.tbl_deep_extend(
      "force",
      client.config.settings({
        Lua = {
          workspace = {
            library = paths,
          },
        },
      })
    )
    client.config.settings = vim.tbl_deep_extend("force", client.config.settings or {}, settings)
  end,
}
return config
