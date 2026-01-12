local M = {}

local uv = vim.loop

local function rpc_error_to_string(err)
  if err == nil or err == vim.NIL then
    return "unknown error"
  end
  if type(err) == "table" then
    return vim.inspect(err)
  end
  return tostring(err)
end

local function usage()
  return table.concat({
    "usage:",
    "  nvim -l nvim/lua/kyoh86/poc/uigrid_snapshot.lua [options]",
    "",
    "options:",
    "  --case PATH        Run case directory (case.json + scenario.lua)",
    "  --json-out PATH    JSON output path ('-' for stdout, 'none' to skip)",
    "  --ansi-out PATH    Write ANSI preview ('-' for stdout)",
    "  --html-out PATH    Write HTML preview ('-' for stdout)",
    "  --width N          UI columns (default: 80)",
    "  --height N         UI lines (default: 24)",
    "  --script PATH      Execute Lua scenario file before snapshot (repeatable)",
    "  --data-home PATH   XDG_DATA_HOME for embedded nvim",
    "  --config-home PATH XDG_CONFIG_HOME for embedded nvim",
    "  --wait MS          Wait for redraw flush (default: 200)",
    "  --rpc-timeout MS   RPC request timeout (default: 2000)",
    "  --nvim PATH        Embedded nvim path (default: nvim)",
    "  --multigrid        Enable ext_multigrid",
    "  -h, --help         Show this help",
  }, "\n")
end

local function parse_args(args)
  local opts = {
    scripts = {},
    wait = 200,
    json_out = "-",
    width = 80,
    height = 24,
    nvim = "nvim",
    rpc_timeout = 2000,
    ansi_out = nil,
    html_out = nil,
    data_home = nil,
    config_home = nil,
    case = nil,
    _flags = {
      json_out = false,
      ansi_out = false,
      html_out = false,
      script = false,
      case = false,
    },
  }
  local i = 1
  while i <= #args do
    local arg = args[i]
    if arg == "--case" then
      local value = args[i + 1]
      if value == nil then
        opts.invalid = opts.invalid or {}
        table.insert(opts.invalid, "--case requires a value")
      else
        opts.case = value
        opts._flags.case = true
        i = i + 1
      end
    elseif vim.startswith(arg, "--case=") then
      opts.case = string.sub(arg, 8)
      opts._flags.case = true
    elseif arg == "--out" then
      local value = args[i + 1]
      if value == nil then
        opts.invalid = opts.invalid or {}
        table.insert(opts.invalid, "--out requires a value")
      else
        opts.json_out = value
        opts._flags.json_out = true
        i = i + 1
      end
    elseif vim.startswith(arg, "--out=") then
      opts.json_out = string.sub(arg, 7)
      opts._flags.json_out = true
    elseif arg == "--json-out" then
      local value = args[i + 1]
      if value == nil then
        opts.invalid = opts.invalid or {}
        table.insert(opts.invalid, "--json-out requires a value")
      else
        opts.json_out = value
        opts._flags.json_out = true
        i = i + 1
      end
    elseif vim.startswith(arg, "--json-out=") then
      opts.json_out = string.sub(arg, 12)
      opts._flags.json_out = true
    elseif arg == "--ansi-out" then
      local value = args[i + 1]
      if value == nil then
        opts.invalid = opts.invalid or {}
        table.insert(opts.invalid, "--ansi-out requires a value")
      else
        opts.ansi_out = value
        opts._flags.ansi_out = true
        i = i + 1
      end
    elseif vim.startswith(arg, "--ansi-out=") then
      opts.ansi_out = string.sub(arg, 12)
      opts._flags.ansi_out = true
    elseif arg == "--html-out" then
      local value = args[i + 1]
      if value == nil then
        opts.invalid = opts.invalid or {}
        table.insert(opts.invalid, "--html-out requires a value")
      else
        opts.html_out = value
        opts._flags.html_out = true
        i = i + 1
      end
    elseif vim.startswith(arg, "--html-out=") then
      opts.html_out = string.sub(arg, 12)
      opts._flags.html_out = true
    elseif arg == "--width" then
      local value = args[i + 1]
      if value == nil then
        opts.invalid = opts.invalid or {}
        table.insert(opts.invalid, "--width requires a value")
      else
        opts.width = tonumber(value) or opts.width
        i = i + 1
      end
    elseif vim.startswith(arg, "--width=") then
      opts.width = tonumber(string.sub(arg, 9)) or opts.width
    elseif arg == "--height" then
      local value = args[i + 1]
      if value == nil then
        opts.invalid = opts.invalid or {}
        table.insert(opts.invalid, "--height requires a value")
      else
        opts.height = tonumber(value) or opts.height
        i = i + 1
      end
    elseif vim.startswith(arg, "--height=") then
      opts.height = tonumber(string.sub(arg, 10)) or opts.height
    elseif arg == "--script" then
      local value = args[i + 1]
      if value == nil then
        opts.invalid = opts.invalid or {}
        table.insert(opts.invalid, "--script requires a value")
      else
        table.insert(opts.scripts, value)
        opts._flags.script = true
        i = i + 1
      end
    elseif vim.startswith(arg, "--script=") then
      table.insert(opts.scripts, string.sub(arg, 10))
      opts._flags.script = true
    elseif arg == "--data-home" then
      local value = args[i + 1]
      if value == nil then
        opts.invalid = opts.invalid or {}
        table.insert(opts.invalid, "--data-home requires a value")
      else
        opts.data_home = vim.fn.fnamemodify(value, ":p")
        i = i + 1
      end
    elseif vim.startswith(arg, "--data-home=") then
      opts.data_home = vim.fn.fnamemodify(string.sub(arg, 12), ":p")
    elseif arg == "--config-home" then
      local value = args[i + 1]
      if value == nil then
        opts.invalid = opts.invalid or {}
        table.insert(opts.invalid, "--config-home requires a value")
      else
        opts.config_home = vim.fn.fnamemodify(value, ":p")
        i = i + 1
      end
    elseif vim.startswith(arg, "--config-home=") then
      opts.config_home = vim.fn.fnamemodify(string.sub(arg, 14), ":p")
    elseif arg == "--wait" then
      local value = args[i + 1]
      if value == nil then
        opts.invalid = opts.invalid or {}
        table.insert(opts.invalid, "--wait requires a value")
      else
        opts.wait = tonumber(value) or opts.wait
        i = i + 1
      end
    elseif vim.startswith(arg, "--wait=") then
      opts.wait = tonumber(string.sub(arg, 8)) or opts.wait
    elseif arg == "--rpc-timeout" then
      local value = args[i + 1]
      if value == nil then
        opts.invalid = opts.invalid or {}
        table.insert(opts.invalid, "--rpc-timeout requires a value")
      else
        opts.rpc_timeout = tonumber(value) or opts.rpc_timeout
        i = i + 1
      end
    elseif vim.startswith(arg, "--rpc-timeout=") then
      opts.rpc_timeout = tonumber(string.sub(arg, 15)) or opts.rpc_timeout
    elseif arg == "--nvim" then
      local value = args[i + 1]
      if value == nil then
        opts.invalid = opts.invalid or {}
        table.insert(opts.invalid, "--nvim requires a value")
      else
        opts.nvim = value
        i = i + 1
      end
    elseif vim.startswith(arg, "--nvim=") then
      opts.nvim = string.sub(arg, 8)
    elseif arg == "--multigrid" then
      opts.multigrid = true
    elseif arg == "--help" or arg == "-h" then
      opts.help = true
    else
      opts.unknown = opts.unknown or {}
      table.insert(opts.unknown, arg)
    end
    i = i + 1
  end
  return opts
end

local function normalize_path(base, path)
  if not path then
    return nil
  end
  if vim.fn.fnamemodify(path, ":p") == path then
    return vim.fs.normalize(path)
  end
  return vim.fs.normalize(vim.fs.joinpath(base, path))
end

local function load_case(opts)
  local case_dir = vim.fs.normalize(vim.fn.fnamemodify(opts.case, ":p"))
  if vim.fn.isdirectory(case_dir) ~= 1 then
    return nil, string.format("case dir not found: %s", case_dir)
  end
  local config_path = vim.fs.joinpath(case_dir, "case.json")
  local config = {}
  if vim.fn.filereadable(config_path) == 1 then
    local fd, err = io.open(config_path, "r")
    if not fd then
      return nil, err
    end
    local text = fd:read("*a")
    fd:close()
    local ok, decoded = pcall(vim.json.decode, text)
    if not ok then
      return nil, string.format("failed to parse case.json: %s", decoded)
    end
    if type(decoded) == "table" then
      config = decoded
    end
  end

  local scenario = config.scenario or "scenario.lua"
  local scenario_path = normalize_path(case_dir, scenario)
  if vim.fn.filereadable(scenario_path) ~= 1 then
    return nil, string.format("scenario not found: %s", scenario_path)
  end

  if type(config.width) == "number" then
    opts.width = config.width
  end
  if type(config.height) == "number" then
    opts.height = config.height
  end

  local out_dir = config.out_dir or ".out"
  local out_dir_path = normalize_path(case_dir, out_dir)
  local outputs = config.outputs or {}
  local default_outputs = {
    json = "snapshot.json",
    ansi = "snapshot.ansi",
    html = "snapshot.html",
  }
  local function resolve_output(key)
    local value = outputs[key]
    if value == nil then
      value = default_outputs[key]
    end
    if value == false or value == "none" then
      return nil
    end
    if value == "-" then
      return "-"
    end
    if type(value) == "string" then
      return normalize_path(out_dir_path, value)
    end
    return nil
  end

  opts.json_out = resolve_output("json")
  opts.ansi_out = resolve_output("ansi")
  opts.html_out = resolve_output("html")
  opts.data_home = normalize_path(case_dir, config.data_home or ".nvim-data")
  opts.config_home = normalize_path(case_dir, config.config_home or ".nvim-config")
  opts.scripts = { scenario_path }

  return opts
end

local function alloc_row(cols)
  local row = {}
  for c = 1, cols do
    row[c] = { text = " ", hl_id = 0 }
  end
  return row
end

local function ensure_grid(grid, rows, cols)
  grid.rows = rows
  grid.cols = cols
  grid.cells = grid.cells or {}
  for r = 1, rows do
    local row = grid.cells[r]
    if not row then
      grid.cells[r] = alloc_row(cols)
    else
      if #row < cols then
        for c = #row + 1, cols do
          row[c] = { text = " ", hl_id = 0 }
        end
      elseif #row > cols then
        for c = cols + 1, #row do
          row[c] = nil
        end
      end
    end
  end
  for r = rows + 1, #grid.cells do
    grid.cells[r] = nil
  end
end

local function clear_grid(grid)
  if not grid.rows or not grid.cols then
    return
  end
  for r = 1, grid.rows do
    local row = grid.cells[r]
    if not row then
      row = alloc_row(grid.cols)
      grid.cells[r] = row
    else
      for c = 1, grid.cols do
        row[c] = { text = " ", hl_id = 0 }
      end
    end
  end
end

local function copy_cell(cell)
  return { text = cell.text, hl_id = cell.hl_id }
end

local function scroll_grid(grid, top, bot, left, right, rows)
  if rows == 0 or not grid.cells then
    return
  end
  local top_r = top + 1
  local bot_r = bot
  local left_c = left + 1
  local right_c = right
  if rows > 0 then
    for r = top_r, bot_r - rows do
      local src = grid.cells[r + rows]
      local dst = grid.cells[r]
      for c = left_c, right_c do
        dst[c] = copy_cell(src[c])
      end
    end
    for r = bot_r - rows + 1, bot_r do
      local row = grid.cells[r]
      for c = left_c, right_c do
        row[c] = { text = " ", hl_id = 0 }
      end
    end
  else
    local offset = -rows
    for r = bot_r, top_r + offset, -1 do
      local src = grid.cells[r - offset]
      local dst = grid.cells[r]
      for c = left_c, right_c do
        dst[c] = copy_cell(src[c])
      end
    end
    for r = top_r, top_r + offset - 1 do
      local row = grid.cells[r]
      for c = left_c, right_c do
        row[c] = { text = " ", hl_id = 0 }
      end
    end
  end
end

local function start_embedded_nvim(opts)
  local env = {}
  for key, value in pairs(uv.os_environ()) do
    if key ~= "XDG_DATA_HOME" and key ~= "XDG_CONFIG_HOME" then
      env[#env + 1] = key .. "=" .. value
    end
  end
  if opts.data_home then
    env[#env + 1] = "XDG_DATA_HOME=" .. opts.data_home
  end
  if opts.config_home then
    env[#env + 1] = "XDG_CONFIG_HOME=" .. opts.config_home
  end

  local stdin = uv.new_pipe(false)
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)
  local state = { exited = false, exit_code = nil, exit_signal = nil }
  local args = { "--embed", "--headless", "-u", "NONE", "-i", "NONE", "-n" }
  local handle, pid = uv.spawn(opts.nvim, {
    args = args,
    env = env,
    stdio = { stdin, stdout, stderr },
  }, function(code, signal)
    state.exited = true
    state.exit_code = code
    state.exit_signal = signal
  end)
  if not handle then
    return nil, string.format("failed to spawn %s", opts.nvim)
  end
  return {
    handle = handle,
    pid = pid,
    stdin = stdin,
    stdout = stdout,
    stderr = stderr,
    state = state,
  }
end

local function new_rpc_client(proc, opts)
  local client = {
    proc = proc,
    msgid = 0,
    buffer = "",
    unpacker = vim.mpack.Unpacker(),
    responses = {},
    rpc_timeout = opts.rpc_timeout,
    on_notification = function() end,
    stderr_chunks = {},
  }

  local function handle_message(msg)
    local kind = msg[1]
    if kind == 1 then
      local id = msg[2]
      client.responses[id] = { err = msg[3], result = msg[4] }
    elseif kind == 2 then
      local method = msg[2]
      local params = msg[3] or {}
      client.on_notification(method, params)
    elseif kind == 0 then
      local id = msg[2]
      client:send({ 1, id, "request not supported", vim.NIL })
    end
  end

  local function feed(chunk)
    if not chunk then
      return
    end
    client.buffer = client.buffer .. chunk
    local pos = 1
    while pos <= #client.buffer do
      local ok, msg, next_pos = pcall(client.unpacker, client.buffer, pos)
      if not ok then
        break
      end
      pos = next_pos
      handle_message(msg)
    end
    if pos > 1 then
      client.buffer = string.sub(client.buffer, pos)
    end
  end

  proc.stdout:read_start(function(err, chunk)
    if err then
      client.last_error = err
      return
    end
    feed(chunk)
  end)

  proc.stderr:read_start(function(_, chunk)
    if chunk then
      table.insert(client.stderr_chunks, chunk)
    end
  end)

  function client:send(msg)
    local ok, err = pcall(function()
      self.proc.stdin:write(vim.mpack.encode(msg))
    end)
    if not ok then
      return false, err
    end
    return true
  end

  function client:request(method, params)
    self.msgid = self.msgid + 1
    local id = self.msgid
    local ok, err = self:send({ 0, id, method, params or {} })
    if not ok then
      return nil, err
    end
    local done = vim.wait(self.rpc_timeout, function()
      return self.responses[id] ~= nil or self.proc.state.exited
    end, 5)
    if not done then
      return nil, "rpc timeout"
    end
    if self.proc.state.exited then
      return nil, "nvim exited"
    end
    local resp = self.responses[id]
    self.responses[id] = nil
    if resp.err ~= nil and resp.err ~= vim.NIL then
      return nil, resp.err
    end
    return resp.result
  end

  function client:notify(method, params)
    return self:send({ 2, method, params or {} })
  end

  return client
end

local function collect_snapshot(opts)
  local state = {
    grids = {},
    hl_attrs = {},
    hl_groups = {},
    default_colors = {},
    got_flush = false,
  }

  local proc, err = start_embedded_nvim(opts)
  if not proc then
    return nil, err
  end

  local client = new_rpc_client(proc, opts)
  client.on_notification = function(method, params)
    if method ~= "redraw" then
      return
    end
    local function handle_event(name, args)
      if name == "grid_resize" then
        local grid, width, height = args[1], args[2], args[3]
        state.grids[grid] = state.grids[grid] or {}
        if type(width) == "number" and type(height) == "number" then
          ensure_grid(state.grids[grid], height, width)
        end
      elseif name == "grid_clear" then
        local grid = args[1]
        state.grids[grid] = state.grids[grid] or {}
        clear_grid(state.grids[grid])
      elseif name == "grid_destroy" then
        local grid = args[1]
        state.grids[grid] = nil
      elseif name == "grid_line" then
        local grid, row, col_start, cells = args[1], args[2], args[3], args[4]
        local g = state.grids[grid]
        if g then
          local r = row + 1
          local c = col_start + 1
          local current_hl = 0
          local row_cells = g.cells[r]
          if row_cells then
            for _, cell in ipairs(cells) do
              local text = cell[1]
              if cell[2] ~= nil then
                current_hl = cell[2]
              end
              local repeat_count = cell[3] or 1
              for _ = 1, repeat_count do
                row_cells[c] = { text = text, hl_id = current_hl }
                c = c + 1
              end
            end
          end
        end
      elseif name == "grid_scroll" then
        local grid, top, bot, left, right, rows = args[1], args[2], args[3], args[4], args[5], args[6]
        local g = state.grids[grid]
        if g then
          scroll_grid(g, top, bot, left, right, rows)
        end
      elseif name == "default_colors_set" then
        state.default_colors = {
          rgb_fg = args[1],
          rgb_bg = args[2],
          rgb_sp = args[3],
          cterm_fg = args[4],
          cterm_bg = args[5],
        }
      elseif name == "hl_attr_define" then
        local id, rgb_attr, cterm_attr, info = args[1], args[2], args[3], args[4]
        state.hl_attrs[id] = {
          rgb_attr = rgb_attr,
          cterm_attr = cterm_attr,
          info = info,
        }
      elseif name == "hl_group_set" then
        local group, hl_id = args[1], args[2]
        state.hl_groups[group] = hl_id
      elseif name == "flush" then
        state.got_flush = true
      end
    end

    for _, ev in ipairs(params) do
      local name = ev[1]
      for i = 2, #ev do
        local args = ev[i]
        if type(args) == "table" then
          handle_event(name, args)
        end
      end
    end
  end

  local attach_opts = {
    ext_linegrid = true,
    ext_hlstate = true,
    ext_multigrid = opts.multigrid or false,
  }
  local _, attach_err = client:request("nvim_ui_attach", { opts.width, opts.height, attach_opts })
  if attach_err then
    return nil, rpc_error_to_string(attach_err)
  end

  for _, path in ipairs(opts.scripts) do
    local _, script_err = client:request("nvim_exec_lua", {
      "local p = ...; dofile(p)",
      { path },
    })
    if script_err then
      return nil, string.format("failed to run --script %q: %s", path, rpc_error_to_string(script_err))
    end
  end

  state.got_flush = false
  client:request("nvim_command", { "redraw" })
  vim.wait(opts.wait, function()
    return state.got_flush or proc.state.exited
  end, 5)

  client:notify("nvim_command", { "qa!" })
  vim.wait(opts.rpc_timeout, function()
    return proc.state.exited
  end, 10)

  local grids = {}
  for id, grid in pairs(state.grids) do
    table.insert(grids, {
      id = id,
      rows = grid.rows,
      cols = grid.cols,
      cells = grid.cells,
    })
  end
  table.sort(grids, function(a, b)
    return a.id < b.id
  end)

  local hl_attrs = {}
  for id, attr in pairs(state.hl_attrs) do
    table.insert(hl_attrs, {
      id = id,
      rgb_attr = attr.rgb_attr,
      cterm_attr = attr.cterm_attr,
      info = attr.info,
    })
  end
  table.sort(hl_attrs, function(a, b)
    return a.id < b.id
  end)

  local hl_groups = {}
  for name, hl_id in pairs(state.hl_groups) do
    table.insert(hl_groups, {
      name = name,
      hl_id = hl_id,
    })
  end
  table.sort(hl_groups, function(a, b)
    return a.name < b.name
  end)

  return {
    size = { columns = opts.width, lines = opts.height },
    default_colors = state.default_colors,
    hl_attrs = hl_attrs,
    hl_groups = hl_groups,
    grids = grids,
  }
end

local function rgb_to_ansi(color, is_bg)
  if color == nil or color == vim.NIL then
    return nil
  end
  if type(color) ~= "number" or color < 0 then
    return nil
  end
  local r = math.floor(color / 65536) % 256
  local g = math.floor(color / 256) % 256
  local b = color % 256
  return string.format("\x1b[%d;2;%d;%d;%dm", is_bg and 48 or 38, r, g, b)
end

local function render_ansi(snapshot)
  local grid = nil
  for _, g in ipairs(snapshot.grids or {}) do
    if g.id == 1 then
      grid = g
      break
    end
  end
  if not grid and snapshot.grids and snapshot.grids[1] then
    grid = snapshot.grids[1]
  end
  if not grid then
    return ""
  end

  local default_fg = snapshot.default_colors and snapshot.default_colors.rgb_fg or nil
  local default_bg = snapshot.default_colors and snapshot.default_colors.rgb_bg or nil

  local attr_map = {}
  for _, attr in ipairs(snapshot.hl_attrs or {}) do
    attr_map[attr.id] = attr.rgb_attr or {}
  end

  local function to_style(hl_id)
    local attr = attr_map[hl_id] or {}
    local fg = attr.foreground
    local bg = attr.background
    local reverse = attr.reverse == true
    if fg == nil then
      fg = default_fg
    end
    if bg == nil then
      bg = default_bg
    end
    if reverse then
      fg, bg = bg, fg
    end
    return {
      fg = fg,
      bg = bg,
      bold = attr.bold == true,
      italic = attr.italic == true,
      underline = attr.underline == true
        or attr.undercurl == true
        or attr.underdouble == true
        or attr.underdotted == true
        or attr.underdashed == true,
      strikethrough = attr.strikethrough == true,
      reverse = reverse,
    }
  end

  local function style_equal(a, b)
    return a.fg == b.fg
      and a.bg == b.bg
      and a.bold == b.bold
      and a.italic == b.italic
      and a.underline == b.underline
      and a.strikethrough == b.strikethrough
      and a.reverse == b.reverse
  end

  local function style_to_ansi(style)
    local codes = { "\x1b[0m" }
    if style.bold then
      table.insert(codes, "\x1b[1m")
    end
    if style.italic then
      table.insert(codes, "\x1b[3m")
    end
    if style.underline then
      table.insert(codes, "\x1b[4m")
    end
    if style.strikethrough then
      table.insert(codes, "\x1b[9m")
    end
    local fg = rgb_to_ansi(style.fg, false)
    local bg = rgb_to_ansi(style.bg, true)
    if fg then
      table.insert(codes, fg)
    end
    if bg then
      table.insert(codes, bg)
    end
    return table.concat(codes)
  end

  local out = {}
  for r = 1, grid.rows do
    local row_cells = grid.cells[r] or {}
    local current = {
      fg = nil,
      bg = nil,
      bold = false,
      italic = false,
      underline = false,
      strikethrough = false,
      reverse = false,
    }
    local line = {}
    for c = 1, grid.cols do
      local cell = row_cells[c] or { text = " ", hl_id = 0 }
      local text = cell.text
      if text == "" then
        text = " "
      end
      local style = to_style(cell.hl_id or 0)
      if not style_equal(style, current) then
        table.insert(line, style_to_ansi(style))
        current = style
      end
      table.insert(line, text)
    end
    table.insert(line, "\x1b[0m")
    table.insert(out, table.concat(line))
  end
  return table.concat(out, "\n")
end

local function to_hex_color(color)
  if color == nil or color == vim.NIL then
    return nil
  end
  if type(color) ~= "number" or color < 0 then
    return nil
  end
  return string.format("#%06x", color)
end

local function escape_html(text)
  return (text:gsub("[&<>\"']", {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;",
    ["'"] = "&#39;",
  }))
end

local function render_html(snapshot)
  local grid = nil
  for _, g in ipairs(snapshot.grids or {}) do
    if g.id == 1 then
      grid = g
      break
    end
  end
  if not grid and snapshot.grids and snapshot.grids[1] then
    grid = snapshot.grids[1]
  end
  if not grid then
    return ""
  end

  local default_fg = snapshot.default_colors and snapshot.default_colors.rgb_fg or nil
  local default_bg = snapshot.default_colors and snapshot.default_colors.rgb_bg or nil

  local attr_map = {}
  for _, attr in ipairs(snapshot.hl_attrs or {}) do
    attr_map[attr.id] = attr.rgb_attr or {}
  end

  local function to_style(hl_id)
    local attr = attr_map[hl_id] or {}
    local fg = attr.foreground
    local bg = attr.background
    local reverse = attr.reverse == true
    if fg == nil then
      fg = default_fg
    end
    if bg == nil then
      bg = default_bg
    end
    if reverse then
      fg, bg = bg, fg
    end
    return {
      fg = fg,
      bg = bg,
      bold = attr.bold == true,
      italic = attr.italic == true,
      underline = attr.underline == true
        or attr.undercurl == true
        or attr.underdouble == true
        or attr.underdotted == true
        or attr.underdashed == true,
      strikethrough = attr.strikethrough == true,
    }
  end

  local function style_equal(a, b)
    return a.fg == b.fg
      and a.bg == b.bg
      and a.bold == b.bold
      and a.italic == b.italic
      and a.underline == b.underline
      and a.strikethrough == b.strikethrough
  end

  local function style_to_css(style)
    local parts = {}
    local fg = to_hex_color(style.fg)
    local bg = to_hex_color(style.bg)
    if fg then
      table.insert(parts, "color:" .. fg)
    end
    if bg then
      table.insert(parts, "background-color:" .. bg)
    end
    if style.bold then
      table.insert(parts, "font-weight:700")
    end
    if style.italic then
      table.insert(parts, "font-style:italic")
    end
    local decorations = {}
    if style.underline then
      table.insert(decorations, "underline")
    end
    if style.strikethrough then
      table.insert(decorations, "line-through")
    end
    if #decorations > 0 then
      table.insert(parts, "text-decoration:" .. table.concat(decorations, " "))
    end
    return table.concat(parts, ";")
  end

  local lines = {}
  for r = 1, grid.rows do
    local row_cells = grid.cells[r] or {}
    local current = {
      fg = nil,
      bg = nil,
      bold = false,
      italic = false,
      underline = false,
      strikethrough = false,
    }
    local line = {}
    local chunk = {}
    for c = 1, grid.cols do
      local cell = row_cells[c] or { text = " ", hl_id = 0 }
      local text = cell.text
      if text == "" then
        text = " "
      end
      local style = to_style(cell.hl_id or 0)
      if not style_equal(style, current) then
        if #chunk > 0 then
          local css = style_to_css(current)
          if css ~= "" then
            table.insert(line, '<span style="' .. css .. '">' .. escape_html(table.concat(chunk)) .. "</span>")
          else
            table.insert(line, escape_html(table.concat(chunk)))
          end
          chunk = {}
        end
        current = style
      end
      table.insert(chunk, text)
    end
    if #chunk > 0 then
      local css = style_to_css(current)
      if css ~= "" then
        table.insert(line, '<span style="' .. css .. '">' .. escape_html(table.concat(chunk)) .. "</span>")
      else
        table.insert(line, escape_html(table.concat(chunk)))
      end
    end
    table.insert(lines, table.concat(line))
  end

  local bg = to_hex_color(default_bg) or "#000000"
  local fg = to_hex_color(default_fg) or "#ffffff"
  return table.concat({
    "<!doctype html>",
    "<html>",
    "<head>",
    '  <meta charset="utf-8" />',
    "  <title>Neovim UI Snapshot</title>",
    "  <style>",
    "    body {",
    "      margin: 0;",
    "      background: " .. bg .. ";",
    "      color: " .. fg .. ";",
    "      font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;",
    "      line-height: 1.2;",
    "    }",
    "    pre {",
    "      margin: 0;",
    "      padding: 16px;",
    "      white-space: pre;",
    "    }",
    "  </style>",
    "</head>",
    "<body>",
    "  <pre>" .. table.concat(lines, "\n") .. "</pre>",
    "</body>",
    "</html>",
  }, "\n")
end

local function write_output(out, contents)
  if out == "-" then
    io.write(contents)
    io.write("\n")
    return true
  end
  local dir = vim.fn.fnamemodify(out, ":h")
  if dir and dir ~= "." then
    vim.fn.mkdir(dir, "p")
  end
  local fd, err = io.open(out, "w")
  if not fd then
    return false, err
  end
  fd:write(contents)
  fd:close()
  return true
end

function M.main(args)
  local opts = parse_args(args)
  if opts.help then
    print(usage())
    return
  end
  if opts.case then
    if opts._flags.json_out or opts._flags.ansi_out or opts._flags.html_out or opts._flags.script then
      vim.api.nvim_err_writeln("--case cannot be combined with output/script options")
      vim.api.nvim_err_writeln(usage())
      vim.cmd("cq")
      return
    end
    local loaded, err = load_case(opts)
    if not loaded then
      vim.api.nvim_err_writeln(err or "failed to load case")
      vim.cmd("cq")
      return
    end
    opts = loaded
  end
  if opts.json_out == "none" then
    opts.json_out = nil
  end
  local stdout_count = 0
  for _, out in ipairs({ opts.json_out, opts.ansi_out, opts.html_out }) do
    if out == "-" then
      stdout_count = stdout_count + 1
    end
  end
  if stdout_count > 1 then
    vim.api.nvim_err_writeln("stdout is shared by multiple outputs; choose one")
    vim.api.nvim_err_writeln(usage())
    vim.cmd("cq")
    return
  end
  if opts.invalid then
    vim.api.nvim_err_writeln("invalid args:")
    for _, msg in ipairs(opts.invalid) do
      vim.api.nvim_err_writeln("  " .. msg)
    end
    vim.api.nvim_err_writeln(usage())
    vim.cmd("cq")
    return
  end
  if opts.unknown then
    vim.api.nvim_err_writeln("unknown args: " .. table.concat(opts.unknown, " "))
    vim.api.nvim_err_writeln(usage())
    vim.cmd("cq")
    return
  end

  local snapshot, err = collect_snapshot(opts)
  if not snapshot then
    vim.api.nvim_err_writeln(err or "snapshot failed")
    vim.cmd("cq")
    return
  end

  if opts.json_out then
    local encoded = vim.json.encode(snapshot)
    local ok, write_err = write_output(opts.json_out, encoded)
    if not ok then
      vim.api.nvim_err_writeln(write_err or "failed to write output")
      vim.cmd("cq")
    end
  end
  if opts.ansi_out then
    local ansi = render_ansi(snapshot)
    local ok_ansi, err_ansi = write_output(opts.ansi_out, ansi)
    if not ok_ansi then
      vim.api.nvim_err_writeln(err_ansi or "failed to write ansi output")
      vim.cmd("cq")
    end
  end
  if opts.html_out then
    local html = render_html(snapshot)
    local ok_html, err_html = write_output(opts.html_out, html)
    if not ok_html then
      vim.api.nvim_err_writeln(err_html or "failed to write html output")
      vim.cmd("cq")
    end
  end
end

if ... then
  return M
end

local ok, err = pcall(M.main, _G.arg or {})
if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd("cq")
end
