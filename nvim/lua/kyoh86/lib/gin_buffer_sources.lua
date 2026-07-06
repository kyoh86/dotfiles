local M = {}

local cache_vars = {
  "my_gin_scheme",
  "my_gin_worktree",
  "my_gin_params",
  "my_gin_fragment",
  "my_gin_source",
  "my_gin_source_label",
}

local function clear_cache(bufnr)
  for _, name in ipairs(cache_vars) do
    vim.b[bufnr][name] = nil
  end
end

local function is_ginedit(bufnr)
  return vim.startswith(vim.api.nvim_buf_get_name(bufnr), "ginedit://")
end

local function request_cache(bufnr)
  if vim.fn.exists("*denops#request_async") == 0 then
    return
  end
  pcall(vim.fn["denops#request_async"], "gin-buffer-sources", "cache", { bufnr }, function()
    vim.schedule(function()
      M.update_visible_worktrees()
      vim.cmd("redrawstatus")
    end)
  end, function(err)
    vim.schedule(function()
      vim.notify(("gin-buffer-sources: %s"):format(err), vim.log.levels.WARN)
    end)
  end)
end

function M.update(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if is_ginedit(bufnr) then
    request_cache(bufnr)
    return
  end
  clear_cache(bufnr)
  M.update_worktree(bufnr)
end

local function current_tab_diff_windows()
  local wins = {}
  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_get_option_value("diff", { win = winid }) then
      table.insert(wins, winid)
    end
  end
  return wins
end

local function path_matches(worktree, fragment, filename)
  if worktree == "" or fragment == "" or filename == "" then
    return false
  end
  local expected = vim.fs.normalize(vim.fs.joinpath(worktree, fragment))
  local actual = vim.fs.normalize(filename)
  return expected == actual
end

function M.update_worktree(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].buftype ~= "" then
    return
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)
  for _, winid in ipairs(current_tab_diff_windows()) do
    local other = vim.api.nvim_win_get_buf(winid)
    if other ~= bufnr and vim.b[other].my_gin_scheme == "ginedit" then
      if path_matches(vim.b[other].my_gin_worktree or "", vim.b[other].my_gin_fragment or "", filename) then
        vim.b[bufnr].my_gin_scheme = "file"
        vim.b[bufnr].my_gin_worktree = vim.b[other].my_gin_worktree
        vim.b[bufnr].my_gin_fragment = vim.b[other].my_gin_fragment
        vim.b[bufnr].my_gin_source = "worktree"
        vim.b[bufnr].my_gin_source_label = "WORKTREE"
        return
      end
    end
  end
end

function M.update_visible_worktrees()
  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(winid) then
      local bufnr = vim.api.nvim_win_get_buf(winid)
      if not is_ginedit(bufnr) then
        clear_cache(bufnr)
        M.update_worktree(bufnr)
      end
    end
  end
end

function M.source_label(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local label = vim.b[bufnr].my_gin_source_label
  if label and label ~= "" then
    return label
  end
  return nil
end

function M.setup()
  local au = require("kyoh86.lib.autocmd").group("kyoh86.lib.gin_buffer_sources", true)
  au:hook({ "BufEnter", "BufWinEnter", "WinEnter" }, {
    callback = function(ev)
      M.update(ev.buf)
    end,
  })
  au:hook("User", {
    pattern = "DenopsPluginPost:gin-buffer-sources",
    callback = function()
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) then
          M.update(bufnr)
        end
      end
    end,
  })
end

return M
