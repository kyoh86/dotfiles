local P = require("kyoh86.lib.pick")
local M = {}

function M.read(file, cwd)
  local stream = io.open(file, "r")
  if not stream then
    return
  end
  local first = stream:read("*l")
  local ok, header = pcall(vim.json.decode, first or "")
  local meta = ok and type(header) == "table" and header.type == "session_meta" and header.payload or nil
  if type(meta) ~= "table" or type(meta.cwd) ~= "string" or type(meta.id) ~= "string" then
    stream:close()
    return
  end
  local path = meta.cwd:gsub("/+$", "")
  if cwd ~= "/" and path ~= cwd and path:sub(1, #cwd + 1) ~= cwd .. "/" then
    stream:close()
    return
  end
  local stats = { user = 0, assistant = 0, tools = 0, contexts = 0, compacted = 0, lines = 1 }
  local tail = {}
  for line in stream:lines() do
    stats.lines = stats.lines + 1
    local valid, entry = pcall(vim.json.decode, line)
    if valid and type(entry) == "table" then
      local payload = type(entry.payload) == "table" and entry.payload or {}
      if entry.type == "turn_context" then
        stats.contexts = stats.contexts + 1
      elseif entry.type == "compacted" then
        stats.compacted = stats.compacted + 1
      elseif entry.type == "response_item" and payload.type == "message" then
        if stats[payload.role] then
          stats[payload.role] = stats[payload.role] + 1
        end
        local parts = {}
        for _, content in ipairs(type(payload.content) == "table" and payload.content or {}) do
          if type(content) == "string" then
            parts[#parts + 1] = content
          elseif type(content) == "table" and type(content.text) == "string" then
            parts[#parts + 1] = content.text
          end
        end
        tail[#tail + 1] = (payload.role or "message") .. ": " .. table.concat(parts)
        if #tail > 10 then
          table.remove(tail, 1)
        end
      elseif entry.type == "response_item" and type(payload.type) == "string" and payload.type:match("_call$") then
        stats.tools = stats.tools + 1
      end
    end
  end
  stream:close()
  local title = tail[#tail] or meta.id
  local trivial = stats.lines <= 3 and stats.assistant == 0 and stats.contexts == 0 and stats.compacted == 0 and stats.tools == 0
  return {
    text = (meta.timestamp or "") .. " " .. (trivial and "[trivial] " or "") .. "U" .. stats.user .. "/A" .. stats.assistant .. "/T" .. stats.tools .. " " .. vim.fs.basename(path) .. " " .. title:gsub("\n", " "):sub(1, 160) .. " " .. path,
    id = meta.id,
    cwd = meta.cwd,
    file = file,
    stats = stats,
    tail = tail,
    meta = meta,
  }
end

function M.sessions()
  local cwd = vim.fn.getcwd():gsub("/+$", "")
  if cwd == "" then
    cwd = "/"
  end
  local root = (vim.env.CODEX_HOME or vim.fn.expand("~/.codex")) .. "/sessions"
  P.start("Codex sessions", function(update)
    local files = vim.fn.globpath(root, "**/*.jsonl", false, true)
    table.sort(files, function(a, b)
      return a > b
    end)
    local items, index = {}, 1
    local buffer = require("mini.pick").get_picker_state().buffers.main
    local function step()
      local state = require("mini.pick").get_picker_state()
      if not state or state.buffers.main ~= buffer then
        return
      end
      local file = files[index]
      if not file then
        update(items)
        return
      end
      local item = M.read(file, cwd)
      if item then
        items[#items + 1] = item
        update(vim.deepcopy(items))
      end
      index = index + 1
      vim.schedule(step)
    end
    vim.schedule(step)
  end, {
    choose = function(item)
      P.terminal({ "codex", "resume", item.id }, item.cwd)
    end,
    preview = function(buf, item)
      P.preview(buf, {
        "# " .. item.id,
        "",
        "cwd: " .. item.cwd,
        "model: " .. (item.meta.model or ""),
        "stats: " .. vim.inspect(item.stats),
        "",
        table.concat(item.tail, "\n\n"),
      }, "markdown")
    end,
    actions = {
      {
        name = "セッションを削除",
        key = "<C-d>",
        run = function(items)
          P.confirm("Delete " .. #items .. " session(s)?", function()
            for _, item in ipairs(items) do
              local success, err = vim.uv.fs_unlink(item.file)
              if not success then
                P.notify(err)
              end
            end
            M.sessions()
          end)
        end,
      },
      { name = "JSONLを開く", key = "<C-e>", run = P.each(function(item)
        vim.cmd.edit(vim.fn.fnameescape(item.file))
      end) },
    },
  })
end

function M.setup()
  P.register("codex-session", "<leader>fcs", "Codex セッション", M.sessions)
end

return M
