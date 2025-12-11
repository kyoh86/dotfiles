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
    screen = Screen.new(6, 2)
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
hell^o       |
            |
    ]])
  end)
end)
