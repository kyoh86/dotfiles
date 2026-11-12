local P = require("kyoh86.lib.pick")
local M = {}

local splits = {
  left = { vertical = true, split = "aboveleft" },
  right = { vertical = true, split = "belowright" },
  leftmost = { vertical = true, split = "topleft" },
  rightmost = { vertical = true, split = "botright" },
  above = { split = "aboveleft" },
  below = { split = "belowright" },
  top = { split = "topleft" },
  bottom = { split = "botright" },
  tab = { tab = "." },
}

local function show(buf, opener)
  opener = opener or {}
  if opener.reuse then
    local win = vim.fn.bufwinid(buf)
    if win ~= -1 then
      vim.api.nvim_set_current_win(win)
      return
    end
  end
  if splits[opener.split] then
    vim.cmd.sbuffer({ args = { tostring(buf) }, mods = splits[opener.split] })
  else
    vim.api.nvim_set_current_buf(buf)
  end
end

local function new_buffer(name, kind, body)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.bo[buf].buftype, vim.bo[buf].bufhidden, vim.bo[buf].swapfile = kind, "hide", false
  vim.api.nvim_buf_set_name(buf, name)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, P.content(body))
  vim.bo[buf].filetype, vim.bo[buf].modified = "markdown", false
  return buf
end

local function view_args(target)
  local args = { "gh", target.kind or "issue", "view", target.url or tostring(target.number) }
  if target.repo then
    vim.list_extend(args, { "--repo", target.repo })
  end
  local fields = "title,body,url"
  if target.kind ~= "pr" then
    fields = fields .. ",number,state,comments"
  end
  return vim.list_extend(args, { "--json", fields })
end

local function fetch(target, done)
  P.command(view_args(target), { cwd = target.cwd }, function(text)
    done(P.json(text))
  end)
end

local function body(data)
  return type(data.body) == "string" and data.body or ""
end

local function editor(name, initial, command, opener, refresh, is_new_comment)
  local existing = vim.fn.bufnr(name)
  if existing ~= -1 and vim.api.nvim_buf_is_loaded(existing) then
    return show(existing, opener)
  end
  if existing ~= -1 then
    vim.api.nvim_buf_delete(existing, {})
  end
  local buf = new_buffer(name, "acwrite", initial)
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
      if is_new_comment and vim.trim(text) == "" then
        error("GitHub comment is empty", 0)
      end
      local args, stdin = command(text)
      local result = vim.system(args, { text = true, stdin = stdin }):wait()
      if result.code ~= 0 then
        error(vim.trim(result.stderr or "gh failed"), 0)
      end
      vim.bo[buf].modified = false
      if is_new_comment then
        vim.bo[buf].buftype, vim.bo[buf].modifiable = "nofile", false
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_delete(buf, {})
          end
        end)
      end
      if refresh then
        refresh()
      end
    end,
  })
  show(buf, opener)
end

local function edit_body(data, kind, opener, refresh)
  editor("github-edit://" .. data.url, body(data), function(text)
    return { "gh", kind, "edit", data.url, "--body-file", "-" }, text
  end, opener, refresh)
end

local function render(buf, data)
  local lines = { "# " .. data.title, "", data.url, "", "## " .. data.state, "" }
  vim.list_extend(lines, P.content(body(data)))
  local sections = {}
  for _, comment in ipairs(data.comments or {}) do
    lines[#lines + 1] = ""
    local author = type(comment.author) == "table" and comment.author.login or "unknown"
    lines[#lines + 1] = "## @" .. author .. " · " .. comment.createdAt
    sections[#sections + 1] = { start = #lines, comment = comment }
    lines[#lines + 1] = ""
    vim.list_extend(lines, P.content(body(comment)))
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable, vim.bo[buf].modified = false, false
  return sections
end

function M.open(target, opener)
  local origin = vim.api.nvim_get_current_win()
  fetch(target, function(data)
    if not vim.api.nvim_win_is_valid(origin) then
      return
    end
    vim.api.nvim_set_current_win(origin)
    local name = "github-view://" .. data.url
    local buf = vim.fn.bufnr(name)
    if buf == -1 or not vim.api.nvim_buf_is_loaded(buf) then
      if buf ~= -1 then
        vim.api.nvim_buf_delete(buf, {})
      end
      buf = new_buffer(name, "nofile", "")
    end
    local sections = render(buf, data)
    local function refresh()
      fetch({ url = data.url }, function(updated)
        if vim.api.nvim_buf_is_loaded(buf) then
          sections = render(buf, updated)
        end
      end)
    end
    local host, repo = data.url:match("^https?://([^/]+)/([^/]+/[^/]+)/issues/%d+$")
    local function cursor_comment()
      local row = vim.api.nvim_win_get_cursor(0)[1]
      for index = #sections, 1, -1 do
        if row >= sections[index].start then
          return sections[index].comment
        end
      end
    end
    local function map(key, action, desc)
      vim.keymap.set("n", "<leader>" .. key, action, { buffer = buf, nowait = true, desc = desc })
    end
    for key, offset in pairs({ n = 1, p = -1 }) do
      map(key, function()
        if repo and data.number + offset > 0 then
          M.open({ number = data.number + offset, repo = host .. "/" .. repo }, { reuse = true })
        end
      end, offset > 0 and "次の GitHub Issue" or "前の GitHub Issue")
    end
    map("e", function()
      local comment = cursor_comment()
      if not comment then
        return edit_body(data, "issue", { split = "above", reuse = true }, refresh)
      end
      local id = type(comment.url) == "string" and comment.url:match("#issuecomment%-(%d+)$")
      if id and repo then
        editor("github-edit://" .. comment.url, body(comment), function(text)
          return { "gh", "api", "--hostname", host, "--method", "PATCH", "repos/" .. repo .. "/issues/comments/" .. id, "--input", "-" }, vim.json.encode({ body = text })
        end, { split = "above", reuse = true }, refresh)
      end
    end, "GitHub Issue の本文・コメントを編集")
    map("c", function()
      editor("github-comment://" .. data.url, "", function(text)
        return { "gh", "issue", "comment", data.url, "--body-file", "-" }, text
      end, { split = "below", reuse = true }, refresh, true)
    end, "GitHub Issue にコメントを追加")
    map("b", function()
      local comment = cursor_comment()
      P.browse({ url = comment and comment.url or data.url })
    end, "GitHub Issue・コメントをブラウザで開く")
    show(buf, opener)
  end)
end

function M.edit(target)
  local win = vim.api.nvim_get_current_win()
  local name = "github-edit://" .. target.url
  local existing = vim.fn.bufnr(name)
  if existing ~= -1 and vim.api.nvim_buf_is_loaded(existing) then
    return show(existing)
  end
  fetch(target, function(data)
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
      edit_body(data, target.kind)
    end
  end)
end

return M
