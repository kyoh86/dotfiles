local group = vim.api.nvim_create_augroup("kyoh86-conf-tomlvsinp", { clear = true })

local function snippet_dirs()
  local candidates = vim.g.vsnip_snippet_dirs or {}
  table.insert(candidates, 1, vim.g.vsnip_snippet_dir)
  return candidates
end
---@param dir string link-followd full path
---@return boolean true if the dir is a snippets directory
local function match_paths(dir, candidates)
  for _, c in pairs(candidates) do
    if vim.fn.resolve(vim.fn.expand(c)) == vim.fn.resolve(vim.fn.expand(dir)) then
      return true
    end
  end
  return false
end

local function open_snippet(item, mods)
  local ext = "toml"
  local cmd = "edit"
  if mods.split ~= "" or mods.horizontal or mods.vertical then
    cmd = "new"
  end

  local expanded_dir = vim.fn.expand(vim.g.vsnip_snippet_dir)
  vim.api.nvim_cmd({ cmd = cmd, args = { string.format("%s/%s.%s", vim.fn.resolve(expanded_dir), item, ext) }, mods = mods }, {})
end

vim.api.nvim_create_user_command("Snip", function(args)
  local candidates = kyoh86.fa.vsnip.source.filetypes(vim.fn.bufnr("%"))
  if args.bang then
    open_snippet(candidates[1], args.smods)
    return
  end
  vim.ui.select(candidates, { prompt = "Select type" }, function(item, index)
    if index == nil then
      return
    end
    open_snippet(item, args.smods)
  end)
end, { desc = "Edit snippet for the current file-type", force = true, bang = true })

vim.api.nvim_create_autocmd("BufWritePost", {
  group = group,
  pattern = "*.toml",
  callback = function(ev)
    local path = vim.fn.resolve(vim.fn.fnamemodify(ev.file, ":p"))
    local candidates = snippet_dirs()
    if not match_paths(vim.fn.fnamemodify(path, ":h"), candidates) then
      return
    end
    kyoh86.fa.denops.request("tomlvsnip", "process", {
      path,
      vim.fn.fnamemodify(ev.file, ":t"),
      candidates,
      table.concat(vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false), "\n"),
      4,
    })
  end,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = group,
  pattern = "*.json",
  callback = function(ev)
    local path = vim.fn.resolve(vim.fn.fnamemodify(ev.file, ":p"))
    local candidates = snippet_dirs()
    if not match_paths(vim.fn.fnamemodify(path, ":h"), candidates) then
      return
    end
    vim.api.nvim_buf_create_user_command(ev.buf, "DeconvertToTOML", function()
      kyoh86.fa.denops.request("tomlvsnip", "deconvert", {
        path,
        table.concat(vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false), "\n"),
        4,
      })
    end, {})
  end,
})
