local M = {}

-- GitHubの認証を得る
function M.login()
  local glaze = require("kyoh86.lib.glaze")
  if not glaze.has("github-auth") then
    -- ref: ../../../../denops/github/handler/login.ts
    vim.fn["denops#request_async"]("github", "login", {}, function(v)
      glaze.set("github-auth", v)
    end, function(e)
      vim.notify("failed to login\n" .. vim.json.encode(e), vim.log.levels.WARN)
    end)
  end
end

-- GitHubの認証を得る
function M.relogin()
  local glaze = require("kyoh86.lib.glaze")
  -- ref: ../../../../denops/github/handler/login.ts
  vim.fn["denops#request_async"]("github", "login", {}, function(v)
    glaze.set("github-auth", v)
  end, function(e)
    vim.notify("failed to login\n" .. vim.json.encode(e), vim.log.levels.WARN)
  end)
end

-- GitHubの認証をddu-source-githubに渡す
function M.auth_ddu()
  local glaze = require("kyoh86.lib.glaze")
  glaze.get("github-auth", function(value, fail)
    local status, err = pcall(vim.fn["ddu#source#github#ensure_login"], value)
    if not status then
      vim.notify("failed to login GitHub with glazed token " .. vim.inspect(err), vim.log.levels.WARN)
      fail()
    end
  end)
end

return M
