local function resolved(path)
  return vim.fn.resolve(vim.fn.fnamemodify(vim.fn.expand(path), ":p")):gsub("/+$", "")
end

local function snippet_dirs()
  local primary = vim.g.vsnip_snippet_dir or vim.fs.joinpath(vim.fn.stdpath("config"), "vsnip")
  local dirs = { resolved(primary) }
  for _, dir in ipairs(vim.g.vsnip_snippet_dirs or {}) do
    dir = resolved(dir)
    if not vim.list_contains(dirs, dir) then
      dirs[#dirs + 1] = dir
    end
  end
  return dirs
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

  local expanded_dir = snippet_dirs()[1]
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
      return open_new_snippet(mods, cmd, expanded_dir, filetype)
    end
    vim.api.nvim_cmd({ cmd = cmd, mods = mods, args = { item } }, {})
  end)
end

local function open_snippet_command(args)
  local ok, candidates = pcall(vim.fn["vsnip#source#filetypes"], vim.api.nvim_get_current_buf())
  if not ok then
    candidates = { vim.bo.filetype }
  end
  if not candidates[1] or candidates[1] == "" then
    error("Set the buffer filetype before editing snippets", 0)
  end
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
end

vim.api.nvim_create_user_command("Snip", open_snippet_command, { desc = "Edit snippet for the current file-type", force = true, bang = true })
vim.api.nvim_create_user_command("Vsnip", open_snippet_command, { desc = "Edit snippet for the current file-type", force = true, bang = true })

local function convert(args, stdin)
  local tool = require("kyoh86.lib.dotfiles_tool")("nvim-tools")
  local result = vim.system(vim.list_extend({ tool, "snippets" }, args), { text = true, stdin = stdin }):wait()
  if result.code ~= 0 then
    error(vim.trim(result.stderr or "Snippet conversion failed"), 0)
  end
end

local group = vim.api.nvim_create_augroup("kyoh86.conf.tomlvsnip", { clear = true })
vim.api.nvim_create_autocmd("BufWritePost", {
  group = group,
  pattern = "*.toml",
  callback = function(event)
    local path = vim.fn.fnamemodify(event.file, ":p")
    local dirs = snippet_dirs()
    if vim.list_contains(dirs, resolved(vim.fs.dirname(path))) then
      convert(vim.list_extend({ "compile", path }, dirs))
    end
  end,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost" }, {
  group = group,
  pattern = "*.json",
  callback = function(event)
    local path = vim.fn.fnamemodify(event.file, ":p")
    if vim.list_contains(snippet_dirs(), resolved(vim.fs.dirname(path))) then
      vim.api.nvim_buf_create_user_command(event.buf, "DeconvertToTOML", function()
        local text = table.concat(vim.api.nvim_buf_get_lines(event.buf, 0, -1, false), "\n")
        convert({ "decompile", path }, text)
      end, { desc = "Convert this snippet JSON to TOML" })
    end
  end,
})
