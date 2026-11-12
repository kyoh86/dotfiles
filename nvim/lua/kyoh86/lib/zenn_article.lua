local M = {}

local function options(args)
  local opts = { title = "", type = "tech", emoji = "🐼", published = false, cwd = vim.fn.getcwd() }
  local flags = { slug = true, title = true, type = true, emoji = true, ["publication-name"] = true }
  local index = 1
  while index <= #args do
    local arg = args[index]
    local key, value = arg:match("^%-%-([%w-]+)=(.*)$")
    if arg == "--published" then
      opts.published = true
    elseif arg:match("^%+%+cwd=.+$") then
      opts.cwd = vim.fn.fnamemodify(arg:sub(7), ":p")
    else
      if not key then
        key = arg:match("^%-%-([%w-]+)$")
        if key and flags[key] and args[index + 1] and not args[index + 1]:match("^%-%-") then
          index = index + 1
          value = args[index]
        end
      end
      if not key or not flags[key] or value == nil then
        error("Invalid Zenn article option: " .. arg, 0)
      end
      opts[key] = value
    end
    index = index + 1
  end
  if opts.slug and (#opts.slug < 12 or #opts.slug > 50 or not opts.slug:match("^[a-z0-9_-]+$")) then
    error("Zenn slug must contain 12–50 characters from a-z, 0-9, - and _", 0)
  end
  if opts.type ~= "tech" and opts.type ~= "idea" then
    error("Zenn article type must be tech or idea", 0)
  end
  return opts
end

local function random_slug()
  local bytes, err = vim.uv.random(8)
  if not bytes then
    error(err, 0)
  end
  return (bytes:gsub(".", function(byte)
    return string.format("%02x", byte:byte())
  end))
end

local function article_emoji(value)
  local alias = value:match("^:?([a-z0-9_+-]+):?$")
  if alias then
    local path = vim.api.nvim_get_runtime_file("data/pick-emoji.json", false)[1]
    if path then
      for _, item in ipairs(vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))) do
        if item.slug == alias then
          return item.emoji
        end
      end
    end
    error("Unknown Zenn emoji: " .. value, 0)
  end
  if value == "" then
    return "🐼"
  end
  return value
end

function M.create(command)
  local opts = options(command.fargs)
  local dir = vim.fs.joinpath(opts.cwd, "articles")
  if vim.fn.isdirectory(dir) == 0 then
    error("Zenn articles directory does not exist: " .. dir, 0)
  end
  local lines = {
    "---",
    "title: " .. vim.json.encode(opts.title),
    "emoji: " .. vim.json.encode(article_emoji(opts.emoji)),
    "type: " .. vim.json.encode(opts.type),
    "topics: []",
    "published: " .. tostring(opts.published),
  }
  if opts["publication-name"] and opts["publication-name"] ~= "" then
    lines[#lines + 1] = "publication_name: " .. vim.json.encode(opts["publication-name"])
  end
  vim.list_extend(lines, { "---", "" })
  local content = table.concat(lines, "\n") .. "\n"
  for _ = 1, 5 do
    local path = vim.fs.joinpath(dir, (opts.slug or random_slug()) .. ".md")
    local fd, err, code = vim.uv.fs_open(path, "wx", 438)
    if fd then
      local written, write_err = vim.uv.fs_write(fd, content, 0)
      local closed, close_err = vim.uv.fs_close(fd)
      if written ~= #content or not closed then
        vim.uv.fs_unlink(path)
        error(write_err or close_err or "Incomplete write: " .. path, 0)
      end
      local mods = command.smods
      local open = mods and (mods.vertical or mods.horizontal or mods.split ~= "") and vim.cmd.split or vim.cmd.edit
      open({ args = { path }, mods = mods })
      return
    end
    if opts.slug or code ~= "EEXIST" then
      error(err, 0)
    end
  end
  error("Could not generate an unused Zenn slug", 0)
end

return M
