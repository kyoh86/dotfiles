local M = {}

--- Join path segments with "/".
local function join_path(...)
  return table.concat({ ... }, "/")
end

--- Normalize root path; relative paths are resolved from cwd.
local function normalize_root(root, cwd)
  cwd = cwd or vim.fn.getcwd()
  if not root or root == "" then
    return vim.fs.normalize(vim.fs.joinpath(cwd, "test"))
  end
  if vim.fn.isabs(root) == 1 then
    return vim.fs.normalize(root)
  end
  return vim.fs.normalize(vim.fs.joinpath(cwd, root))
end

--- Parse command arguments.
--- Recognizes -cwd=/path or "-cwd /path" as option, returns positionals + opts.
--- @param fargs string[]
local function parse_args(fargs)
  local opts = {}
  local positionals = {}
  local i = 1
  while i <= #fargs do
    local arg = fargs[i]
    if vim.startswith(arg, "-cwd=") then
      opts.cwd = string.sub(arg, 6)
    elseif arg == "-cwd" then
      if fargs[i + 1] then
        opts.cwd = fargs[i + 1]
        i = i + 1
      end
    else
      table.insert(positionals, arg)
    end
    i = i + 1
  end
  return positionals, opts
end

--- Notify error via vim.notify
--- @param err string|unknown|nil
local function notify_error(err)
  if err then
    vim.notify(err, vim.log.levels.ERROR)
  else
    vim.notify("unidentified error", vim.log.levels.ERROR)
  end
end

--- Write file to the path (overwrite when force=true).
--- @param path string
--- @param contents string
--- @param opts {force?: boolean}?
local function write_file(path, contents, opts)
  opts = opts or {}
  if vim.fn.filereadable(path) == 1 and not opts.force then
    return false, string.format("%s already exists (use force to overwrite)", path)
  end
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local ok, err = pcall(function()
    local fd = assert(io.open(path, "w"))
    fd:write(contents)
    fd:close()
  end)
  if not ok then
    return false, err
  end
  return true
end

--- Run an external command.
--- If the command failed, it returns error with details.
--- @param cmd string[]
--- @param cwd string?
local function system(cmd, cwd)
  local obj = vim.system(cmd, { text = true, cwd = cwd }):wait()
  if obj.code ~= 0 then
    return false, table.concat({
      "cmd: " .. table.concat(cmd, " "),
      "code: " .. obj.code,
      "stdout: " .. obj.stdout,
      "stderr: " .. obj.stderr,
    }, "\n")
  end
  return true
end

-- Pull test/functional from Neovim repo via tarball.
---@param ref string? branch or tag. default "master"
---@param opts {root?:string, force?:boolean, cwd?:string}? options
function M.pull_core(ref, opts)
  ref = ref or "master"
  opts = opts or {}
  local cwd = opts.cwd or vim.fn.getcwd()
  local root = normalize_root(opts.root, cwd)
  local core_dir = join_path(root, "nvimcore")
  local target = join_path(core_dir, "functional")
  if vim.fn.isdirectory(target) == 1 and not opts.force then
    return false, string.format("%s already exists (use force to overwrite)", target)
  end
  vim.fn.delete(target, "rf")
  vim.fn.mkdir(core_dir, "p")
  local url = string.format("https://github.com/neovim/neovim/archive/refs/heads/%s.tar.gz", ref)
  local ok, err = system({
    "sh",
    "-c",
    string.format([[curl -L "%s" | tar xz --strip-components=1 -C "%s" "neovim-%s/test/functional"]], url, core_dir, ref),
  })
  if not ok then
    return false, err
  end
  return true
end

-- Scaffold minimal init and UI test. name is required.
---@param name string
---@param opts {root?:string, force?:boolean, cwd?:string}?
function M.scaffold(name, opts)
  opts = opts or {}
  local cwd = opts.cwd or vim.fn.getcwd()
  local root = normalize_root(opts.root, cwd)
  local core_dir = join_path(root, "nvimcore")
  local ui_dir = join_path(root, "ui")
  local minimal_init = join_path(root, "minimal_init.lua")
  if not name or name == "" then
    return false, "name is required for UITestScaffold"
  end

  local init_body = string.format(
    [[
package.path = "%s" .. "/?.lua;" .. "%s" .. "/?/init.lua;" .. package.path
vim.o.termguicolors = true
vim.o.guicursor = ""
vim.opt.runtimepath:append("%s")
]],
    core_dir,
    core_dir,
    cwd
  )

  local spec_body = string.format(
    [=[
package.path = "%s" .. "/?.lua;" .. "%s" .. "/?/init.lua;" .. package.path

local helpers = require("helpers")(after_each)
local Screen = require("ui.screen")
local feed, clear = helpers.feed, helpers.clear

describe("basic screen check", function()
  local screen

  before_each(function()
    clear({ args = { "-u", "%s", "--cmd", "set shortmess+=I" } })
    screen = Screen.new(40, 8)
    screen:attach()
  end)

  it("echoes input", function()
    feed("ihello<Esc>")
    screen:expect([[
      hello                               |
      ~                                   |
      ~                                   |
      ~                                   |
      ~                                   |
      ~                                   |
      ~                                   |
                                          |
    ]])
  end)
end)
]=],
    core_dir,
    core_dir,
    minimal_init
  )

  local spec_path = join_path(ui_dir, string.format("%s_spec.lua", name))

  local ok, err = write_file(minimal_init, init_body, { force = opts.force })
  if not ok then
    return false, err
  end
  local ok2, err2 = write_file(spec_path, spec_body, { force = opts.force })
  if not ok2 then
    return false, err2
  end
  return true
end

function M.setup_commands()
  vim.api.nvim_create_user_command("UITestPull", function(cmd)
    local pos, opts = parse_args(cmd.fargs)
    local ref = pos[1]
    local ok, err = M.pull_core(ref, { force = cmd.bang, cwd = opts.cwd })
    if not ok then
      notify_error(err)
    else
      vim.notify("pulled test/functional from Neovim " .. (ref or "master"))
    end
  end, {
    nargs = "*",
    bang = true,
    desc = "Pull Neovim test/functional into test/nvimcore (use ! to force overwrite, -cwd for workdir)",
  })

  vim.api.nvim_create_user_command("UITestScaffold", function(cmd)
    local pos, opts = parse_args(cmd.fargs)
    local name = pos[1]
    local ok, err = M.scaffold(name, { force = cmd.bang, cwd = opts.cwd })
    if not ok then
      notify_error(err)
    else
      vim.notify("scaffolded minimal init and ui test (" .. name .. ")")
    end
  end, {
    nargs = "+",
    bang = true,
    desc = "Create minimal init and UI test (use ! to overwrite, -cwd for workdir)",
    complete = function()
      return {}
    end,
  })
end

return M
