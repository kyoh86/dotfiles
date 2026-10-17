-- Run from repository root:
-- nvim --headless -u NONE -i NONE '+luafile nvim/tests/pick_test.lua'
-- NVIM_PICK_PATH / NVIM_EXTRA_PATH can point to isolated plugin checkouts.
vim.opt.rtp:prepend(vim.fn.fnamemodify("nvim", ":p"))
local lazy = vim.fn.stdpath("data") .. "/lazy/"
vim.opt.rtp:prepend(vim.env.NVIM_PICK_PATH or (lazy .. "mini.pick"))
vim.opt.rtp:prepend(vim.env.NVIM_EXTRA_PATH or (lazy .. "mini.extra"))
vim.opt.rtp:prepend(lazy .. "vim-mr")
vim.o.swapfile = false

local P = require("kyoh86.lib.pick")
local pick = require("mini.pick")
local errors = {}
vim.notify = function(message, level)
  if level == vim.log.levels.ERROR then
    errors[#errors + 1] = tostring(message)
  end
end

local function check()
  dofile("nvim/lua/kyoh86/plug/pick.lua").config()
  local count = 0
  for _, entry in pairs(P.registry) do
    count = count + 1
    if entry.key then
      assert(vim.fn.maparg(entry.key, "n") ~= "" or entry.key == "<C-x>y", entry.key)
    end
  end
  assert(count >= 50)
  local timer
  local function interact(start, inspect, keys)
    local attempts = 0
    timer = vim.uv.new_timer()
    timer:start(
      20,
      20,
      vim.schedule_wrap(function()
        attempts = attempts + 1
        local items = pick.get_picker_items()
        if items and #items > 0 then
          timer:stop()
          timer:close()
          P.guard(function()
            inspect(items)
          end)
          vim.api.nvim_input(vim.keycode(keys or "<Esc>"))
        elseif attempts > 150 then
          io.stderr:write("picker timed out\n")
          vim.cmd.cquit()
        end
      end)
    )
    start()
    vim.wait(100, function()
      return false
    end)
    assert(#errors == 0, table.concat(errors, "\n"))
  end

  local file = vim.fn.tempname() .. " spaced.txt"
  vim.fn.writefile({ "fixture" }, file)
  interact(function()
    P.start("Fixture", { { text = "fixture", path = file } })
  end, function(items)
    assert(items[1].path == file)
  end, "<C-v>")
  assert(vim.fn.winnr("$") == 2)
  assert(vim.api.nvim_buf_get_name(0) == file)
  vim.cmd.only()

  local chosen
  interact(function()
    P.start("Action", { { text = "one", id = 1 }, { text = "two", id = 2 } }, {
      actions = { {
        name = "Selected",
        key = "<C-d>",
        run = function(items)
          chosen = items
        end,
      } },
    })
  end, function() end, "<C-a><C-d>")
  assert(#chosen == 2, "Ctrl action must receive marked items")

  chosen = nil
  interact(function()
    P.start("Marked", { "one", "two" }, {
      choose = function(item)
        chosen = (chosen or "") .. item
      end,
    })
  end, function() end, "<C-a><C-q>")
  assert(chosen == "onetwo", "Ctrl-q must choose marked items")

  local phase = 0
  timer = vim.uv.new_timer()
  timer:start(
    20,
    20,
    vim.schedule_wrap(function()
      local opts = pick.get_picker_opts()
      if not opts or not pick.get_picker_items() then
        return
      end
      if phase == 0 and opts.source.name == "Parent" then
        phase = 1
        vim.api.nvim_input(vim.keycode("<C-o>"))
      elseif phase == 1 and opts.source.name == "Actions: Parent" then
        phase = 2
        vim.api.nvim_input(vim.keycode("<C-]>"))
      elseif phase == 2 and opts.source.name == "Parent" then
        phase = 3
        timer:stop()
        timer:close()
        vim.api.nvim_input(vim.keycode("<Esc>"))
      end
    end)
  )
  vim.defer_fn(function()
    if phase ~= 3 then
      io.stderr:write("action menu/back navigation timed out\n")
      vim.cmd.cquit()
    end
  end, 3000)
  P.start("Parent", { "one" })
  vim.wait(1000, function()
    return phase == 3
  end)
  assert(phase == 3, "Ctrl-o action menu / Ctrl-] back failed")

  -- An async provider belonging to a closed picker must not affect its successor.
  local delayed
  interact(function()
    P.start("Old", function(update)
      delayed = update
      update({ "old" })
    end)
  end, function() end)
  interact(function()
    P.start("New", { "new" })
  end, function(items)
    delayed({ "stale" })
    assert(pick.get_picker_items()[1] == "new")
  end)

  interact(function()
    P.registry.buffer.run({})
  end, function(items)
    assert(items[1].bufnr)
  end)
  interact(function()
    P.registry["file-hide"].run({})
  end, function(items)
    assert(type(items[1]) == "string")
  end)
  interact(function()
    P.registry["emoji-emoji"].run({})
  end, function(items)
    assert(#items > 1800 and items[1].emoji)
  end)

  local history = require("kyoh86.lib.pick.tools").parse_history({
    ": 1:0;echo one",
    ": 2:0;printf \\",
    "two",
    ": 3:0;echo one",
  })
  assert(#history == 2 and history[1].command == "echo one" and history[2].command == "printf \ntwo")

  local session = vim.fn.tempname()
  vim.fn.writefile({
    vim.json.encode({ type = "session_meta", payload = { id = "fixture", cwd = "/work/project", timestamp = "2026-01-01" } }),
    "invalid trailing record",
    vim.json.encode({ type = "response_item", payload = { type = "message", role = "user", content = { { text = "hello" } } } }),
  }, session)
  local sessions = require("kyoh86.lib.pick.sessions")
  assert(sessions.read(session, "/work/project").stats.user == 1)
  assert(sessions.read(session, "/work/pro") == nil, "cwd filtering must respect path boundaries")
  assert(vim.deep_equal(P.content("first\n\nlast\n"), { "first", "", "last" }), "content must retain blank lines")
  vim.fn.delete(session)
  vim.fn.delete(file)
  print("PASS: " .. count .. " pickers; split, Ctrl actions, marked selection, stale async results, files/buffers/emoji, history, sessions")
end

local ok, err = xpcall(check, debug.traceback)
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd.cquit()
end
vim.cmd("qa!")
