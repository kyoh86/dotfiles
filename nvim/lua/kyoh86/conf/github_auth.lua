local group = vim.api.nvim_create_augroup("kyoh86-conf-github-auth", { clear = true })

vim.api.nvim_create_autocmd("User", {
  pattern = "DenopsPluginPost:github-auth",
  group = group,
  callback = function()
    local glaze = require("kyoh86.lib.glaze")
    if not glaze.has("github-auth") then
      vim.fn["denops#request_async"]("github-auth", "login", {}, function(v)
        glaze.set("github-auth", v)
      end, function(e)
        vim.notify("failed to login\n" .. vim.json.encode(e), vim.log.levels.WARN)
      end)
    end
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "DenopsPluginPost:ddu-source-github",
  group = group,
  callback = function()
    local glaze = require("kyoh86.lib.glaze")
    glaze.get("github-auth", function(value)
      vim.fn["ddu#source#github#ensure_login"](value)
    end)
  end,
})
