local M = { registry = {} }

function M.notify(message)
  vim.notify(tostring(message), vim.log.levels.ERROR, { title = "mini.pick" })
end

function M.guard(fn)
  local ok, err = pcall(fn)
  if not ok then
    M.notify(err)
  end
end

function M.lines(text)
  return vim.split(text or "", "\n", { trimempty = true })
end

function M.content(text)
  local lines = vim.split(text or "", "\n", { plain = true })
  if lines[#lines] == "" then
    table.remove(lines)
  end
  return lines
end

-- Commands are argv arrays. Never interpolate a selected value into shell code.
function M.command(argv, opts, callback)
  opts = vim.tbl_extend("force", { text = true }, opts or {})
  local on_error = opts.on_error
  opts.on_error = nil
  local ok, job = pcall(
    vim.system,
    argv,
    opts,
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        if on_error then
          on_error()
        end
        M.notify(argv[1] .. ": " .. vim.trim(result.stderr or "command failed"))
        return
      end
      M.guard(function()
        callback(result.stdout or "")
      end)
    end)
  )
  if not ok then
    if on_error then
      on_error()
    end
    M.notify(job)
  end
  return ok and job or nil
end

function M.json(text)
  local ok, value = pcall(vim.json.decode, text)
  if ok then
    return value
  end
  local values = {}
  for _, line in ipairs(M.lines(text)) do
    values[#values + 1] = vim.json.decode(line)
  end
  return values
end

function M.preview(buf, lines, ft)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, type(lines) == "string" and M.content(lines) or lines)
  if ft then
    vim.bo[buf].filetype = ft
  end
end

function M.text(item)
  return type(item) == "string" and item or item.text
end

function M.insert(text, before)
  vim.api.nvim_put(vim.split(text, "\n", { plain = true }), "c", not before, true)
end

function M.terminal(argv, cwd)
  vim.cmd.enew()
  vim.fn.jobstart(argv, { term = true, cwd = cwd })
  vim.cmd.startinsert()
end

function M.browse(item)
  require("kyoh86.lib.open").gui(item.url or item.path or M.text(item))
end

function M.open(item)
  if type(item) == "table" and item.open then
    return item.open(item)
  end
  require("mini.pick").default_choose(item)
end

-- Close the picker before editing, prompting, or starting another picker.
function M.defer(fn)
  local pick = require("mini.pick")
  local state = pick.get_picker_state()
  local target = state and state.windows.target or vim.api.nvim_get_current_win()
  local parent
  if state then
    parent = { opts = pick.get_picker_opts(), query = pick.get_picker_query() }
    parent.opts.source.items = pick.get_picker_items() or {}
  end
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(target) then
      vim.api.nvim_set_current_win(target)
      local previous = M.parent
      M.parent = parent
      M.guard(fn)
      M.parent = previous
    end
  end)
end

function M.selected()
  local matches = require("mini.pick").get_picker_matches() or {}
  if matches.marked and #matches.marked > 0 then
    return matches.marked
  end
  return matches.current and { matches.current } or {}
end

function M.each(fn)
  return function(items)
    for _, item in ipairs(items) do
      fn(item)
    end
  end
end

function M.confirm(prompt, fn)
  if vim.fn.confirm(prompt, "&Yes\n&No", 2) == 1 then
    fn()
  end
end

-- Each action has a single Ctrl chord and a discoverable label.
function M.options(name, actions, source)
  local pick = require("mini.pick")
  actions = actions or {}
  local mappings = {}
  local parent = M.parent
  if parent then
    mappings.back = {
      char = "<C-]>",
      func = function()
        M.defer(function()
          vim.schedule(function()
            if pick.is_picker_active() then
              pick.set_picker_query(parent.query)
            end
          end)
          pick.start(parent.opts)
        end)
        return true
      end,
    }
  end
  local function invoke(action)
    local items = M.selected()
    if #items == 0 then
      return
    end
    M.defer(function()
      action.run(items)
    end)
    return true
  end
  for _, action in ipairs(actions) do
    if action.key then
      -- Disable a built-in mapping if this picker uses its chord for an action.
      for builtin, key in pairs(pick.config.mappings) do
        if type(key) == "string" and key:lower() == action.key:lower() then
          mappings[builtin] = ""
        end
      end
      mappings[action.name] = {
        char = action.key,
        func = function()
          return invoke(action)
        end,
      }
    end
  end
  mappings.actions = {
    char = "<C-o>",
    func = function()
      local items = M.selected()
      local choose = pick.get_picker_opts().source.choose or M.open
      M.defer(function()
        local choices = {}
        for _, action in ipairs(actions) do
          choices[#choices + 1] = { text = (action.key or "") .. "  " .. action.name, action = action }
        end
        choices[#choices + 1] = {
          text = "<CR>  選択",
          action = { run = M.each(choose) },
        }
        M.start("Actions: " .. name, choices, {
          choose = function(choice)
            choice.action.run(items)
          end,
        })
      end)
      return true
    end,
  }
  return { source = vim.tbl_extend("force", { name = name }, source or {}), mappings = mappings }
end

function M.start(name, items, opts)
  opts = opts or {}
  local choose = opts.choose or M.open
  local source = {
    choose = function(item)
      M.defer(function()
        choose(item)
      end)
    end,
    choose_marked = function(marked)
      M.defer(function()
        for _, item in ipairs(marked) do
          choose(item)
        end
      end)
    end,
    preview = opts.preview,
    cwd = opts.cwd,
  }
  source.items = type(items) ~= "function" and items or function()
    local pick = require("mini.pick")
    local buffer = pick.get_picker_state().buffers.main
    local function update(values)
      local state = pick.get_picker_state()
      if state and state.buffers.main == buffer then
        pick.set_picker_items(values)
      end
    end
    items(update)
  end
  return require("mini.pick").start(M.options(name, opts.actions, source))
end

function M.cli(name, argv, transform, opts)
  return M.start(name, function(update)
    M.command(argv, {
      cwd = opts and opts.cwd,
      on_error = function()
        update({})
      end,
    }, function(text)
      update(transform and transform(text) or M.lines(text))
    end)
  end, opts)
end

function M.register(name, key, desc, fn, mode)
  M.registry[name] = { key = key, desc = desc, run = fn }
  require("mini.pick").registry[name] = function(opts)
    M.guard(function()
      fn(opts or {})
    end)
  end
  if key then
    vim.keymap.set(mode or "n", key, function()
      M.guard(function()
        fn({})
      end)
    end, { desc = "[pick] " .. desc })
  end
end

function M.menu()
  local items = {}
  for name, entry in pairs(M.registry) do
    items[#items + 1] = { text = (entry.key or "") .. "  " .. entry.desc .. "  (" .. name .. ")", entry = entry }
  end
  table.sort(items, function(a, b)
    return a.text < b.text
  end)
  M.start("Pickers", items, {
    choose = function(item)
      item.entry.run({})
    end,
  })
end

function M.setup()
  for _, module in ipairs({ "editor", "git", "github", "tools", "services", "sessions" }) do
    require("kyoh86.lib.pick." .. module).setup()
  end
end

return M
