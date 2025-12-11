local script_dir = vim.fs.dirname(vim.fs.normalize(debug.getinfo(1, "S").source:sub(2)))
local project_root = vim.fs.normalize(script_dir .. "/../..")

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
    n.exec_lua([[
      local root = ...
      package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path
      vim.opt.runtimepath:append(root)
    ]], project_root)
    screen = Screen.new(20, 6)
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
    screen:expect({
      grid = [[
      hell^o               |
      ~                   |
      ~                   |
      ~                   |
      ~                   |
                          |
    ]],
      attr_ids = {},
    })
  end)

  it("screen.show_ghost shows the text in the line", function()
    feed("iline1<CR>line2<CR>line3<Esc>")
    screen:expect({
      grid = [[
      line1               |
      line2               |
      line^3               |
      ~                   |
      ~                   |
                          |
    ]],
      attr_ids = {},
    })

    local buf = n.api.nvim_get_current_buf()
    n.api.nvim_win_set_cursor(0, { 1, 0 })
    n.exec_lua([[require("kyoh86.poc.codex_ghost.screen").show_ghost(...)]], { buf = buf, row = 0, col = 0 }, { "ghost1", "ghost2" }, { color = "never" })
    n.command("redraw!")
    screen:expect({
      grid = [[
      ^line1               |
      ghost1              |
      ghost2              |
      line2               |
      line3               |
                          |
    ]],
      attr_ids = {},
    })
  end)
end)
