return {
  on_init = function(client)
    local settings = {
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
          library = {
            vim.fn.expand("~/.luarocks/share/lua/5.3"),
            "/usr/share/lua/5.3",
          },
          checkThirdParty = false,
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
    }
    if client.workspace_folders[1].name == vim.env.DOTFILES .. "/nvim" then
      local plugins = require("lazy.core.config").plugins
      local paths = {
        vim.fs.joinpath(vim.fn.stdpath("config") --[[@as string]], "lua"),
        vim.fs.joinpath(vim.env.VIMRUNTIME, "lua"),
        "${3rd}/luv/library",
        "${3rd}/busted/library",
        "${3rd}/luassert/library",
      }
      for _, plugin in pairs(plugins) do
        local plugin_dir = vim.fs.joinpath(plugin.dir, "lua")
        if vim.fn.isdirectory(plugin_dir) then
          table.insert(paths, plugin_dir)
        end
      end
      settings = vim.tbl_deep_extend("force", {
        Lua = {
          workspace = {
            library = paths,
          },
        },
      })
    end
    client.config.settings = vim.tbl_deep_extend("force", client.config.settings or {}, settings)
  end,
}
