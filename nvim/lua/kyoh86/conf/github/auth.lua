local M = {}

-- GitHubの認証を得る
function M.login()
  local glaze = require("kyoh86.lib.glaze")
  if not glaze.has("github-auth") then
    M.relogin(glaze)
  end
end

-- GitHubの認証を得る
function M.relogin(glaze)
  glaze = glaze or require("kyoh86.lib.glaze")
  -- ref: ../../../../denops/github/handler/login.ts
  vim.fn["denops#request_async"]("github", "login", {}, function(v)
    vim.validate("github-auth", v, "table")
    vim.validate("github-auth.clientType", v.clientType, "string")
    vim.validate("github-auth.clientId", v.clientId, "string")
    vim.validate("github-auth.type", v.type, "string")
    vim.validate("github-auth.tokenType", v.tokenType, "string")
    vim.validate("github-auth.token", v.token, "string")
    glaze.set("github-auth", v)
  end, function(e)
    vim.notify("failed to login\n" .. vim.json.encode(e), vim.log.levels.WARN)
  end)
end

-- GitHubの認証をddu-source-githubに渡す
function M.auth_ddu()
  local glaze = require("kyoh86.lib.glaze")
  glaze.get_async("github-auth", function(value, fail)
    local status, err = pcall(vim.fn["ddu#source#github#ensure_login"], value)
    if not status then
      vim.notify("failed to login GitHub with glazed token " .. vim.inspect(err), vim.log.levels.WARN)
      fail()
    end
  end)
end

return M
