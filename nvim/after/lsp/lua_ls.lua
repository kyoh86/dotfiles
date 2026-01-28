local function first(list)
  if list == nil or #list == 0 then
    return nil
  end
  return list[1]
end

local libs = {
  "/usr/share/lua/5.1",
  vim.fn.expand("~/Projects/github.com/kyoh86/gogh/lua"),
}

-- LSがNeovim設定ディレクトリ以下で起動されてるかチェック
local function ls_for_nvim(client)
  local folder = first(client.workspace_folders)
  if folder == nil then
    return false
  end
  if vim.uv.fs_realpath(folder.name) ~= vim.uv.fs_realpath(vim.env.DOTFILES .. "/nvim") then
    return false
  end
  return true
end

---@type vim.lsp.Config
local config = {
  cmd = { "lua-language-server", "--locale", "ja-jp" },
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
        library = libs,
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
    if not ls_for_nvim(client) then
      return
    end

    -- Neovim系のライブラリを読み込む
    local paths = vim.list_extend({
      vim.fs.joinpath(vim.fn.stdpath("config") --[[@as string]], "lua"),
      vim.fs.joinpath(vim.env.VIMRUNTIME, "lua"),
      "${3rd}/luv/library",
      "${3rd}/busted/library",
      "${3rd}/luassert/library",
    }, libs)

    -- Neovim系のライブラリを読み込む
    local plugins = require("lazy.core.config").plugins
    for _, plugin in pairs(plugins) do
      local plugin_dir = vim.fs.joinpath(plugin.dir, "lua")
      if vim.fn.isdirectory(plugin_dir) == 1 then
        table.insert(paths, plugin_dir)
      end
    end
    vim.lsp.config(
      "lua_ls",
      vim.tbl_deep_extend("force", client.config.settings or {}, {
        Lua = {
          workspace = {
            library = paths,
          },
        },
      })
    )
  end,
}
return config
