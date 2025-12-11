package.path = "nvim/test/.uitest/nvimcore" .. "/?.lua;" .. "nvim/test/.uitest/nvimcore" .. "/?/init.lua;"
  .. "nvim/test/.uitest/busted" .. "/?.lua;" .. "nvim/test/.uitest/busted" .. "/?/init.lua;"
  .. "nvim/test/.uitest/luassert" .. "/?.lua;" .. "nvim/test/.uitest/luassert" .. "/?/init.lua;"
  .. "nvim/test/.uitest/say" .. "/?.lua;" .. "nvim/test/.uitest/say" .. "/?/init.lua;"
  .. "nvim/test/.uitest/penlight" .. "/lua/?.lua;" .. "nvim/test/.uitest/penlight" .. "/lua/?/init.lua;"
  .. "nvim/test/.uitest/cliargs" .. "/?.lua;" .. "nvim/test/.uitest/cliargs" .. "/?/init.lua;"
  .. "nvim/test/.uitest/mediator" .. "/?.lua;" .. "nvim/test/.uitest/mediator" .. "/?/init.lua;"
  .. "nvim/test/.uitest/plenary" .. "/lua/?.lua;" .. "nvim/test/.uitest/plenary" .. "/lua/?/init.lua;"
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
    screen = Screen.new(20, 6)
    screen:add_extra_attr_ids({
      [100] = { foreground = Screen.colors.NvimLightGrey4 },
    })
    -- screen:set_default_attr_ignore({
    --   { bold = true, italic = true, underline = true, reverse = true, foreground = true, background = true },
    -- })
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
    local ghost_screen = require("kyoh86.poc.codex_ghost.screen")
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

    local buf = vim.api.nvim_get_current_buf()
    ghost_screen.show_ghost({ buf = buf, row = 1, col = 0 }, { "ghost1", "ghost2" }, { color = "never" })
    n.command("redraw")
    screen:expect({
      grid = [[
      line1               |
      ghost1              |
      ghost2              |
      line2               |
      line^3               |
                          |
    ]],
      attr_ids = {},
    })
  end)
end)
