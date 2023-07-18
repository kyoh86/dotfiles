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

local ext = "toml"
local function open_new_snippet(mods, cmd, dir, filetype)
  vim.ui.input({ prompt = "Prefix (if you don't need, empty): " }, function(input)
    if input == nil then
      return
    end
    local filename = (input == "" and string.format("%s/%s.%s", dir, filetype, ext) or string.format("%s/%s.%s.%s", dir, input, filetype, ext))
    vim.api.nvim_cmd({ cmd = cmd, mods = mods, args = { filename } }, {})
  end)
end

local function open_snippet(filetype, mods)
  local cmd = "edit"
  if mods.split ~= "" or mods.horizontal or mods.vertical then
    cmd = "new"
  end

  local expanded_dir = vim.fn.resolve(vim.fn.expand(vim.g.vsnip_snippet_dir))
  local files = vim.list_extend(vim.fn.glob(string.format("%s/*.%s.%s", expanded_dir, filetype, ext), true, true), vim.fn.glob(string.format("%s/%s.%s", expanded_dir, filetype, ext), true, true))
  if #files == 0 then
    return open_new_snippet(mods, cmd, expanded_dir, filetype)
  end
  table.insert(files, 1, "New one")
  vim.ui.select(files, {
    prompt = "Select file to edit: ",
    format_item = function(file)
      return vim.fs.basename(file)
    end,
  }, function(item, idx)
    vim.cmd.redraw()
    if item == nil then
      return
    end
    if idx == 1 then
      -- new one
      return open_new_snippet(mods, cmd, expanded_dir, item)
    end
    vim.api.nvim_cmd({ cmd = cmd, mods = mods, args = { item } }, {})
  end)
end

vim.api.nvim_create_user_command("Snip", function(args)
  local candidates = kyoh86.fa.vsnip.source.filetypes(vim.fn.bufnr("%"))
  if args.bang then
    open_snippet(candidates[1], args.smods)
    return
  end
  vim.ui.select(candidates, { prompt = "Select type" }, function(item, index)
    vim.cmd.redraw()
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
