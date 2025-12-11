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

--- Pull minimal Screen dependencies from Neovim repo via tarball.
---@param ref string? branch or tag. default "master"
---@param opts {root?:string, force?:boolean, cwd?:string}? options
function M.pull_core(ref, opts)
  ref = ref or "master"
  opts = opts or {}
  local cwd = opts.cwd or vim.fn.getcwd()
  local root = normalize_root(opts.root, cwd)
  local vendor_root = join_path(root, ".uitest")
  local core_dir = join_path(vendor_root, "nvimcore")
  local plenary_dir = join_path(vendor_root, "plenary")
  local busted_dir = join_path(vendor_root, "busted")
  local luassert_dir = join_path(vendor_root, "luassert")
  local say_dir = join_path(vendor_root, "say")
  local penlight_dir = join_path(vendor_root, "penlight")
  local cliargs_dir = join_path(vendor_root, "cliargs")
  local mediator_dir = join_path(vendor_root, "mediator")
  local cmakeconfig_dir = join_path(core_dir, "test", "cmakeconfig")
  local paths_lua = join_path(cmakeconfig_dir, "paths.lua")
  if vim.fn.isdirectory(vendor_root) == 1 and not opts.force then
    return false, string.format("%s already exists (use force to overwrite)", vendor_root)
  end
  vim.fn.delete(vendor_root, "rf")
  vim.fn.mkdir(core_dir, "p")
  -- Keep cache out of VCS for consumers
  write_file(join_path(vendor_root, ".gitignore"), "*\n")
  local url = string.format("https://github.com/neovim/neovim/archive/refs/heads/%s.tar.gz", ref)
  local ok, err = system({
    "sh",
    "-c",
    table.concat({
      string.format([[curl -L "%s"]], url),
      [[| tar xz --strip-components=1 --wildcards -C "]] .. core_dir .. [["]],
      [["*/test/*"]],
    }, " "),
  })
  if not ok then
    return false, err
  end
  vim.fn.delete(plenary_dir, "rf")
  vim.fn.mkdir(plenary_dir, "p")
  local plenary_url = "https://github.com/nvim-lua/plenary.nvim/archive/refs/heads/master.tar.gz"
  local ok2, err2 = system({
    "sh",
    "-c",
    table.concat({
      string.format([[curl -L "%s"]], plenary_url),
      [[| tar xz --strip-components=1 -C "]] .. plenary_dir .. [["]],
    }, " "),
  })
  if not ok2 then
    return false, err2
  end
  vim.fn.delete(luassert_dir, "rf")
  vim.fn.mkdir(luassert_dir, "p")
  local luassert_url = "https://github.com/lunarmodules/luassert/archive/refs/heads/master.tar.gz"
  local ok_lua, err_lua = system({
    "sh",
    "-c",
    table.concat({
      string.format([[curl -L "%s"]], luassert_url),
      [[| tar xz --strip-components=2 -C "]] .. luassert_dir .. [[" "luassert-master/src"]],
    }, " "),
  })
  if not ok_lua then
    return false, err_lua
  end
  vim.fn.delete(say_dir, "rf")
  vim.fn.mkdir(say_dir, "p")
  local say_url = "https://github.com/Olivine-Labs/say/archive/refs/heads/master.tar.gz"
  local ok_say, err_say = system({
    "sh",
    "-c",
    table.concat({
      string.format([[curl -L "%s"]], say_url),
      [[| tar xz --strip-components=2 -C "]] .. say_dir .. [[" "say-master/src"]],
    }, " "),
  })
  if not ok_say then
    return false, err_say
  end
  vim.fn.delete(penlight_dir, "rf")
  vim.fn.mkdir(penlight_dir, "p")
  local penlight_url = "https://github.com/lunarmodules/Penlight/archive/refs/heads/master.tar.gz"
  local ok_pl, err_pl = system({
    "sh",
    "-c",
    table.concat({
      string.format([[curl -L "%s"]], penlight_url),
      [[| tar xz --strip-components=1 -C "]] .. penlight_dir .. [[" "Penlight-master/lua"]],
    }, " "),
  })
  if not ok_pl then
    return false, err_pl
  end
  vim.fn.delete(cliargs_dir, "rf")
  vim.fn.mkdir(cliargs_dir, "p")
  local cliargs_url = "https://github.com/amireh/lua_cliargs/archive/refs/heads/master.tar.gz"
  local ok_cli, err_cli = system({
    "sh",
    "-c",
    table.concat({
      string.format([[curl -L "%s"]], cliargs_url),
      [[| tar xz --strip-components=2 -C "]] .. cliargs_dir .. [[" "lua_cliargs-master/src"]],
    }, " "),
  })
  if not ok_cli then
    return false, err_cli
  end
  vim.fn.delete(mediator_dir, "rf")
  vim.fn.mkdir(mediator_dir, "p")
  local mediator_url = "https://github.com/Olivine-Labs/mediator_lua/archive/refs/heads/master.tar.gz"
  local ok_med, err_med = system({
    "sh",
    "-c",
    table.concat({
      string.format([[curl -L "%s"]], mediator_url),
      [[| tar xz --strip-components=2 -C "]] .. mediator_dir .. [[" "mediator_lua-master/src"]],
    }, " "),
  })
  if not ok_med then
    return false, err_med
  end
  vim.fn.delete(busted_dir, "rf")
  vim.fn.mkdir(busted_dir, "p")
  local busted_url = "https://github.com/Olivine-Labs/busted/archive/refs/heads/master.tar.gz"
  local ok_busted, err_busted = system({
    "sh",
    "-c",
    table.concat({
      string.format([[curl -L "%s"]], busted_url),
      [[| tar xz --strip-components=1 -C "]] .. busted_dir .. [[" "busted-master/busted" "busted-master/busted.lua"]],
    }, " "),
  })
  if not ok_busted then
    return false, err_busted
  end
  write_file(
    join_path(penlight_dir, "lua", "lfs.lua"),
    table.concat({
      "-- Minimal LuaFileSystem shim backed by libuv for busted/Penlight.",
      "local uv = vim.loop",
      "",
      "local function err_result(ok, param)",
      "  if ok then",
      "    return ok",
      "  end",
      "  local msg = param or ''",
      "  local code = nil",
      "  if type(param) == 'string' and param:match('^UV_') then",
      "    code = param",
      "  end",
      "  return nil, msg, code",
      "end",
      "",
      "local function to_attributes(stat)",
      "  if not stat then",
      "    return nil",
      "  end",
      "  local mode = stat.type == 'dir' and 'directory'",
      "    or stat.type == 'file' and 'file'",
      "    or stat.type == 'link' and 'link'",
      "    or stat.type",
      "  return {",
      "    dev = stat.dev,",
      "    ino = stat.ino,",
      "    mode = mode,",
      "    nlink = stat.nlink,",
      "    uid = stat.uid,",
      "    gid = stat.gid,",
      "    rdev = stat.rdev,",
      "    access = stat.atime and stat.atime.sec,",
      "    modification = stat.mtime and stat.mtime.sec,",
      "    change = stat.ctime and stat.ctime.sec,",
      "    size = stat.size,",
      "  }",
      "end",
      "",
      "local lfs = {}",
      "",
      "function lfs.attributes(path, selector)",
      "  local stat = uv.fs_stat(path)",
      "  if not stat then",
      "    return nil, 'fs_stat failed', nil",
      "  end",
      "  if selector then",
      "    local attrs = to_attributes(stat)",
      "    return attrs and attrs[selector]",
      "  end",
      "  return to_attributes(stat)",
      "end",
      "",
      "function lfs.symlinkattributes(path, selector)",
      "  local stat = uv.fs_lstat(path)",
      "  if not stat then",
      "    return nil, 'fs_lstat failed', nil",
      "  end",
      "  if selector then",
      "    local attrs = to_attributes(stat)",
      "    return attrs and attrs[selector]",
      "  end",
      "  return to_attributes(stat)",
      "end",
      "",
      "function lfs.currentdir()",
      "  local cwd = uv.cwd()",
      "  return cwd or nil, cwd and nil or 'no cwd'",
      "end",
      "",
      "function lfs.chdir(path)",
      "  local ok, err = pcall(uv.chdir, path)",
      "  return err_result(ok, err)",
      "end",
      "",
      "function lfs.mkdir(path)",
      "  local ok, err = pcall(uv.fs_mkdir, path, 493)",
      "  return err_result(ok, err)",
      "end",
      "",
      "function lfs.rmdir(path)",
      "  local ok, err = pcall(uv.fs_rmdir, path)",
      "  return err_result(ok, err)",
      "end",
      "",
      "function lfs.dir(path)",
      "  local req, err = uv.fs_scandir(path)",
      "  if not req then",
      "    return function()",
      "      return nil, err",
      "    end",
      "  end",
      "  return function()",
      "    return uv.fs_scandir_next(req)",
      "  end",
      "end",
      "",
      "function lfs.setmode(file, mode)",
      "  return true, mode or 'binary'",
      "end",
      "",
      "return lfs",
      "",
    }, "\n"),
    { force = true }
  )
  write_file(
    join_path(busted_dir, "system.lua"),
    table.concat({
      "-- Minimal system module used by busted to avoid external dependency.",
      "local uv = vim.loop",
      "",
      "local function monotime()",
      "  return uv.hrtime() / 1e9",
      "end",
      "",
      "local system = {",
      "  monotime = monotime,",
      "}",
      "",
      "function system.gettime()",
      "  return uv.now() / 1000",
      "end",
      "",
      "function system.sleep(sec)",
      "  uv.sleep(math.floor((sec or 0) * 1000))",
      "end",
      "",
      "return system",
      "",
    }, "\n"),
    { force = true }
  )
  write_file(
    join_path(busted_dir, "term.lua"),
    table.concat({
      "-- Minimal stub for term detection used by busted.",
      "local term = {}",
      "",
      "function term.isatty(_)",
      "  return false",
      "end",
      "",
      "return term",
      "",
    }, "\n"),
    { force = true }
  )
  vim.fn.mkdir(cmakeconfig_dir, "p")
  write_file(
    paths_lua,
    table.concat({
      "local uv = vim.uv",
      "local function exepath()",
      "  local ok, path = pcall(vim.fn.exepath, 'nvim')",
      "  return ok and path or 'nvim'",
      "end",
      "local nvim_prog = exepath()",
      "local nvim_dir = nvim_prog:match('(.+)/[^/]+$') or '.'",
      "return {",
      "  test_build_dir = nvim_dir,",
      "  test_source_path = nvim_dir,",
      "  merged_compiled_dir = nvim_dir,",
      "  cmake_binary_dir = nvim_dir,",
      "  build_type = '',",
      "  is_asan = false,",
      "  is_ubsan = false,",
      "  is_msan = false,",
      "  is_tsan = false,",
      "  is_zig_build = false,",
      "  translations_enabled = false,",
      "  is_win = (uv.os_uname().sysname or ''):lower():match('windows') ~= nil,",
      "}",
      "",
    }, "\n"),
    { force = true }
  )
  return true
end

-- Scaffold minimal init and UI test. name is required.
---@param name string
---@param opts {root?:string, force?:boolean, cwd?:string}?
function M.scaffold(name, opts)
  opts = opts or {}
  local cwd = opts.cwd or vim.fn.getcwd()
  local root = normalize_root(opts.root, cwd)
  local core_dir = join_path(root, ".uitest", "nvimcore")
  local plenary_dir = join_path(root, ".uitest", "plenary")
  local busted_dir = join_path(root, ".uitest", "busted")
  local luassert_dir = join_path(root, ".uitest", "luassert")
  local say_dir = join_path(root, ".uitest", "say")
  local penlight_dir = join_path(root, ".uitest", "penlight")
  local cliargs_dir = join_path(root, ".uitest", "cliargs")
  local mediator_dir = join_path(root, ".uitest", "mediator")
  local ui_dir = join_path(root, "ui")
  local minimal_init = join_path(root, "minimal_init.lua")
  if not name or name == "" then
    return false, "name is required for UITestScaffold"
  end

  local init_body = string.format(
    [[
package.path = "%s" .. "/?.lua;" .. "%s" .. "/?/init.lua;"
  .. "%s" .. "/?.lua;" .. "%s" .. "/?/init.lua;"
  .. "%s" .. "/?.lua;" .. "%s" .. "/?/init.lua;"
  .. "%s" .. "/?.lua;" .. "%s" .. "/?/init.lua;"
  .. "%s" .. "/lua/?.lua;" .. "%s" .. "/lua/?/init.lua;"
  .. "%s" .. "/?.lua;" .. "%s" .. "/?/init.lua;"
  .. "%s" .. "/?.lua;" .. "%s" .. "/?/init.lua;"
  .. "%s" .. "/lua/?.lua;" .. "%s" .. "/lua/?/init.lua;"
  .. package.path
vim.o.termguicolors = true
vim.o.guicursor = ""
vim.env.NVIM_PRG = vim.env.NVIM_PRG or vim.v.progpath
vim.opt.runtimepath:append("%s")
vim.opt.runtimepath:append("%s")
vim.opt.runtimepath:append("%s")
vim.opt.runtimepath:append("%s")
vim.opt.runtimepath:append("%s")
vim.opt.runtimepath:append("%s")
vim.opt.runtimepath:append("%s")
vim.opt.runtimepath:append("%s")
vim.opt.runtimepath:append("%s")
]],
    core_dir,
    core_dir,
    busted_dir,
    busted_dir,
    luassert_dir,
    luassert_dir,
    say_dir,
    say_dir,
    penlight_dir,
    penlight_dir,
    cliargs_dir,
    cliargs_dir,
    mediator_dir,
    mediator_dir,
    plenary_dir,
    plenary_dir,
    plenary_dir,
    busted_dir,
    luassert_dir,
    say_dir,
    penlight_dir,
    cliargs_dir,
    mediator_dir,
    core_dir,
    cwd
  )

  local spec_body = string.format(
    [=[
package.path = "%s" .. "/?.lua;" .. "%s" .. "/?/init.lua;"
  .. "%s" .. "/?.lua;" .. "%s" .. "/?/init.lua;"
  .. "%s" .. "/?.lua;" .. "%s" .. "/?/init.lua;"
  .. "%s" .. "/?.lua;" .. "%s" .. "/?/init.lua;"
  .. "%s" .. "/lua/?.lua;" .. "%s" .. "/lua/?/init.lua;"
  .. "%s" .. "/?.lua;" .. "%s" .. "/?/init.lua;"
  .. "%s" .. "/?.lua;" .. "%s" .. "/?/init.lua;"
  .. "%s" .. "/lua/?.lua;" .. "%s" .. "/lua/?/init.lua;"
  .. package.path

local t = require("test.testutil")
local n = require("test.functional.testnvim")()
local Screen = require("test.functional.ui.screen")
local feed, clear = n.feed, n.clear

describe("basic screen check", function()
  local screen

  before_each(function()
    pcall(function()
      if n.get_session() then
        n.stop()
      end
    end)
    clear()
    screen = Screen.new(40, 8)
    screen:attach()
  end)

  after_each(function()
    if screen then
      screen:detach()
    end
    if n.get_session() then
      n.stop()
    end
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
    busted_dir,
    busted_dir,
    luassert_dir,
    luassert_dir,
    say_dir,
    say_dir,
    penlight_dir,
    penlight_dir,
    cliargs_dir,
    cliargs_dir,
    mediator_dir,
    mediator_dir,
    plenary_dir,
    plenary_dir,
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
      vim.notify("pulled test tree (" .. (ref or "master") .. ") and plenary")
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
