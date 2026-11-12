local M = {}
local documents = {}

function M.command(service, resource)
  local config = vim.env.XDG_CONFIG_HOME
  if not config or config == "" then
    config = vim.fn.expand("~/.config")
  end
  return { config .. "/dotfiles-tool/dest/pick-services", service, resource }
end

local function request(route, resource, payload)
  local command = M.command(route.service, resource)
  if route.domain then
    vim.list_extend(command, { "--domain", route.domain })
  end
  if route.id then
    vim.list_extend(command, { "--id", route.id })
  end
  if route.template then
    vim.list_extend(command, { "--template", route.template })
  end
  local result = vim.system(command, { stdin = payload and vim.json.encode(payload) or nil }):wait()
  if result.code ~= 0 then
    local message = vim.trim(result.stderr or "")
    error(message ~= "" and message or (route.service .. ": " .. resource .. " failed"), 0)
  end
  return vim.json.decode(result.stdout)
end

local function route_for(uri)
  local domain, id = uri:match("^docbase://post;domain=([%w-]+)&postId=(%d+)$")
  if id then
    return { service = "docbase", domain = domain, id = id }
  end
  local template
  domain, template = uri:match("^docbase://new%-post;domain=([%w-]+)&template=(%d+)$")
  domain = domain or uri:match("^docbase://new%-post;domain=([%w-]+)$")
  if domain then
    return { service = "docbase", domain = domain, template = template }
  end
  id = uri:match("^inkdrop://note;noteId=(note:[%w_-]+)$")
  if id then
    return { service = "inkdrop", id = id }
  end
  error("Invalid DocBase or Inkdrop document URI", 0)
end

local function render(route, fields)
  local lines = {}
  if route.service == "docbase" then
    lines = { "---", "title: " .. vim.json.encode(fields.title), "scope: " .. fields.scope, "draft: " .. tostring(fields.draft) }
    for _, key in ipairs({ "tags", "groups" }) do
      if #fields[key] == 0 then
        lines[#lines + 1] = key .. ": []"
      else
        lines[#lines + 1] = key .. ":"
        for _, name in ipairs(fields[key]) do
          lines[#lines + 1] = "  - " .. vim.json.encode(name)
        end
      end
    end
    lines[#lines + 1] = "---"
  elseif fields.title ~= "" then
    lines = { "# " .. fields.title, "" }
  end
  return vim.list_extend(lines, vim.split(fields.body, "\n", { plain = true }))
end

local function parse_string(value)
  if value:sub(1, 1) == '"' then
    local ok, decoded = pcall(vim.json.decode, value)
    if not ok or type(decoded) ~= "string" then
      error("Invalid quoted DocBase front matter value", 0)
    end
    return decoded
  end
  if value:sub(1, 1) == "'" and value:sub(-1) == "'" then
    return (value:sub(2, -2):gsub("''", "'"))
  end
  return value
end

local function parse_docbase(lines)
  if lines[1] ~= "---" then
    error("DocBase post needs front matter delimited by ---", 0)
  end
  local fields = { scope = "private", draft = false, tags = {}, groups = {} }
  local list, seen = nil, {}
  for index = 2, #lines do
    local line = lines[index]
    if line == "---" then
      if not fields.title or vim.trim(fields.title) == "" then
        error("DocBase title is required", 0)
      end
      fields.body = table.concat(lines, "\n", index + 1)
      return fields
    end
    local item = line:match("^%s+%-%s+(.+)$")
    local key, value = line:match("^(%a+):%s*(.-)%s*$")
    if item and list then
      table.insert(fields[list], parse_string(item))
    elseif key and not seen[key] then
      seen[key], list = true, nil
      if key == "title" then
        fields.title = parse_string(value)
      elseif key == "scope" and vim.tbl_contains({ "private", "group", "everyone" }, value) then
        fields.scope = value
      elseif key == "draft" and (value == "true" or value == "false") then
        fields.draft = value == "true"
      elseif (key == "tags" or key == "groups") and value == "" then
        list = key
      elseif key == "tags" or key == "groups" then
        local ok, values = pcall(vim.json.decode, value)
        if not ok or not vim.islist(values) or not vim.iter(values):all(function(name)
          return type(name) == "string"
        end) then
          error("Invalid DocBase front matter list: " .. key, 0)
        end
        fields[key] = values
      else
        error("Invalid DocBase front matter field: " .. key, 0)
      end
    elseif line:match("%S") and not line:match("^%s*#") then
      error("Invalid DocBase front matter on line " .. index, 0)
    end
  end
  error("DocBase front matter is missing its closing ---", 0)
end

local function parse_inkdrop(lines)
  local title = lines[1]:match("^# (.*)$")
  local start = title and (lines[2] == "" and 3 or 2) or 1
  return { title = title or "", body = table.concat(lines, "\n", start) }
end

local function set_metadata(buf, route, metadata)
  vim.b[buf].inkdrop_note_id = route.id
  vim.b[buf].inkdrop_note_book_id = metadata.bookId
  vim.b[buf].inkdrop_note_tag_ids = metadata.tags
  vim.b[buf].inkdrop_note_status = metadata.status
end

local function read(buf, name)
  local options = vim.bo[buf]
  options.buftype, options.swapfile, options.bufhidden = "acwrite", false, "hide"
  local route = route_for(name)
  local result = request(route, "read")
  local lines = render(route, result.fields)
  options.modifiable, options.readonly = true, false
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  options.modified = false
  documents[buf] = { route = route, original = result.fields }
  if route.service == "inkdrop" then
    set_metadata(buf, route, result.metadata)
    options.filetype = "inkdrop_note.markdown"
  else
    options.filetype = route.id and "docbase_post.markdown" or "docbase_new_post.markdown"
  end
end

local function write(buf)
  local document = documents[buf]
  if not document then
    error("Reload the document before saving", 0)
  end
  local route = document.route
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local fields = route.service == "docbase" and parse_docbase(lines) or parse_inkdrop(lines)
  local result = request(route, "write", { fields = fields, original = document.original })
  document.original = result.fields
  if result.metadata then
    set_metadata(buf, route, result.metadata)
  end
  if route.service == "docbase" and not route.id then
    -- Keep the new ID even if the canonical URI already has a buffer.
    route.id, route.template = result.id, nil
    local name = "docbase://post;domain=" .. route.domain .. "&postId=" .. route.id
    local ok = pcall(vim.api.nvim_buf_set_name, buf, name)
    if not ok then
      vim.notify("DocBase post saved as " .. name, vim.log.levels.WARN)
    end
    vim.bo[buf].filetype = "docbase_post.markdown"
  end
  if not vim.deep_equal(fields, result.fields) then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, render(route, result.fields))
  end
  vim.bo[buf].modified = false
end

function M.inkdrop_metadata(buf, action, value)
  local document = documents[buf]
  if not document or document.route.service ~= "inkdrop" then
    vim.notify("Inkdrop ノートを開いてから実行してください", vim.log.levels.WARN)
    return
  end
  local ok, result = pcall(request, document.route, "metadata", { action = action, value = value })
  if ok then
    set_metadata(buf, document.route, result.metadata)
  else
    vim.notify(result, vim.log.levels.ERROR)
  end
end

local function setup_login()
  vim.api.nvim_create_user_command("DocbaseLogin", function()
    local domain = vim.fn.input("DocBase domain: ", "wacul")
    if domain == "" then
      return
    end
    local token = vim.fn.inputsecret("DocBase token: ")
    if token ~= "" then
      request({ service = "docbase", domain = domain }, "login", { token = token })
    end
  end, {})
  vim.api.nvim_create_user_command("InkdropLogin", function()
    local base = vim.fn.input("Inkdrop URL: ", "http://127.0.0.1:19840")
    local username = base ~= "" and vim.fn.input("Inkdrop username: ") or ""
    local password = username ~= "" and vim.fn.inputsecret("Inkdrop password: ") or ""
    if password ~= "" then
      request({ service = "inkdrop" }, "login", { baseUrl = base, username = username, password = password })
    end
  end, {})
end

function M.setup()
  local group = vim.api.nvim_create_augroup("kyoh86.service_documents", { clear = true })
  local patterns = { "docbase://*", "inkdrop://*" }
  vim.api.nvim_create_autocmd("BufReadCmd", {
    group = group,
    pattern = patterns,
    callback = function(event)
      read(event.buf, event.match)
    end,
  })
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    group = group,
    pattern = patterns,
    callback = function(event)
      write(event.buf)
    end,
  })
  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = group,
    callback = function(event)
      documents[event.buf] = nil
    end,
  })
  setup_login()
end

return M
