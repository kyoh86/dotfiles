--- @class kyoh86.poc.ghost.Agent
---@field job? vim.SystemObj
---@field job_timer? table
--- @field opts kyoh86.poc.ghost.Config
--- @field stop_timeout fun(self: kyoh86.poc.ghost.Agent)
--- @field reset fun(self: kyoh86.poc.ghost.Agent)
--- @field request fun(self: kyoh86.poc.ghost.Agent, context: kyoh86.poc.ghost.Context, callback: fun(prompt: string, suggestion: string[]))
local M = {}

--- @class kyoh86.poc.ghost.Position
--- @field buf integer
--- @field row integer
--- @field col integer

--- @class kyoh86.poc.ghost.Context
--- @field filename string
--- @field filetype string
--- @field before string[]
--- @field line string
--- @field after string[]
--- @field pos kyoh86.poc.ghost.Position

--- @param opts kyoh86.poc.ghost.Config
--- @return kyoh86.poc.ghost.Agent
function M.new(opts)
  if vim.fn.executable("codex") == 0 then
    error("codex CLI not found in PATH")
  end
  local instance = {
    job = nil,
    job_timer = nil,
    opts = opts,
  }
  setmetatable(instance, { __index = M })
  return instance
end

function M:stop_timeout()
  if self.job_timer ~= nil and not self.job_timer:is_closing() then
    self.job_timer:stop()
    self.job_timer:close()
  end
  self.job_timer = nil
end

function M:reset()
  if self.job ~= nil then
    pcall(function()
      self.job:kill("term")
    end)
  end
  self:stop_timeout()
  self.job = nil
end

--- Build prompt message to pass to the Codex
--- @param context kyoh86.poc.ghost.Context
local function build_prompt(context)
  return table.concat({
    "You are a code completion engine.",
    "Continue the code at the cursor position.",
    "Return only the continuation to insert (no markdown, no fences, no explanations).",
    "Keep indentation consistent and avoid repeating the existing suffix.",
    string.format("Filetype: %s", context.filetype),
    string.format("Filename: %s", context.filename),
    string.format("Cursor: line %d, column %d", context.pos.row + 1, context.pos.col + 1),
    "--- BEFORE ---",
    table.concat(context.before, "\n"),
    "--- CURRENT ---",
    context.line,
    "--- AFTER ---",
    table.concat(context.after, "\n"),
  }, "\n")
end

local function read_file(path)
  local fd = io.open(path, "r")
  if not fd then
    return nil
  end
  local content = fd:read("*a")
  fd:close()
  return content
end

function M:request(context, callback)
  local prompt = build_prompt(context)
  if not prompt then
    return
  end
  local tmpfile = vim.fn.tempname()

  local args = { "codex", "exec" }
  if self.opts.model ~= nil then
    vim.list_extend(args, { "-m", self.opts.model })
  end
  vim.list_extend(args, { "--color=never", "--skip-git-repo-check", "--output-last-message", tmpfile, "-" })

  self.job = vim.system(args, { stdin = prompt, text = true }, function(obj)
    self:stop_timeout()

    local response_body = read_file(tmpfile)
    os.remove(tmpfile)

    if obj.code ~= 0 then
      vim.notify("Codex failed: " .. (obj.stderr or obj.stdout or "unknown error"), vim.log.levels.ERROR)
      vim.notify(string.format("fail code=%s msg=%s", tostring(obj.code), obj.stderr or obj.stdout or "unknown"), vim.log.levels.TRACE)
      return
    end

    if not response_body then
      vim.notify("Codex suggested empty (or failed to read temp file)")
      return
    end
    local response = response_body:gsub("\r", "")

    if response == "" then
      vim.notify("Codex suggested empty")
      return
    end

    local suggestion = vim.split(response, "\n", { plain = true })
    vim.notify(string.format("ok lines=%d file=%s", #suggestion, context.filename), vim.log.levels.TRACE)
    vim.schedule(function()
      callback(prompt, suggestion)
    end)
    self:reset()
  end)
  if self.opts.timeout_ms > 0 then
    self.job_timer = vim.defer_fn(function()
      if self.job ~= nil then
        vim.notify("Ghost timed out", vim.log.levels.INFO)
        vim.notify("timeout; killing job", vim.log.levels.TRACE)
        self:reset()
      end
    end, self.opts.timeout_ms)
  end
end

return M
