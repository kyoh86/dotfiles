local glaze = require("kyoh86.lib.glaze")

local M = {}

local function detect_opener()
  for _, opener in ipairs({ "wslview", "xdg-open", "open" }) do
    if vim.fn.executable(opener) ~= 0 then
      return opener
    end
  end
  return ""
end

function M.opener()
  local opener = detect_opener()
  if opener ~= "" then
    if glaze.tryget("opener") ~= opener then
      glaze.set("opener", opener)
    end
    return opener
  end

  local cached = glaze.tryget("opener")
  if type(cached) == "string" and cached ~= "" and vim.fn.executable(cached) ~= 0 then
    return cached
  end
  return ""
end

function M.gui(target)
  if target == nil or target == "" then
    vim.notify("No target found to open.", vim.log.levels.WARN)
    return nil
  end

  local opener = M.opener()
  if opener == "" then
    local ok, result = pcall(vim.ui.open, target)
    if not ok then
      vim.notify("Failed to open: " .. tostring(result), vim.log.levels.ERROR)
      return nil
    end
    return result
  end

  local stderr = {}
  local job = vim.fn.jobstart({ opener, target }, {
    stderr_buffered = true,
    on_stderr = function(_, data)
      stderr = data or {}
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        local message = table.concat(
          vim.tbl_filter(function(line)
            return line ~= ""
          end, stderr),
          "\n"
        )
        vim.notify(("Failed to open %s with %s%s"):format(target, opener, message ~= "" and (": " .. message) or "."), vim.log.levels.ERROR)
      end
    end,
  })
  if job <= 0 then
    vim.notify(("Failed to start opener %s for %s."):format(opener, target), vim.log.levels.ERROR)
    return nil
  end
  return job
end

return M
