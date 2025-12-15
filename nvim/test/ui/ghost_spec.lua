local script_dir = vim.fs.dirname(vim.fs.normalize(debug.getinfo(1, "S").source:sub(2)))
local project_root = vim.fs.normalize(script_dir .. "/../..")

local t = require("test.testutil")
local n = require("test.functional.testnvim")()
local feed, clear = n.feed, n.clear
local eq = t.eq

describe("basic screen check", function()
  before_each(function()
    pcall(function()
      if n.get_session() then
        n.stop()
      end
    end)
    clear()
    n.exec_lua(
      [[
      local root = ...
      package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path
      vim.opt.runtimepath:append(root)
      vim.notify = function() end
      require("kyoh86.poc.ghost").setup({ notify_on_cancel = false })
    ]],
      project_root
    )
  end)

  after_each(function()
    if n.get_session() then
      n.stop()
    end
  end)

  it("applies suggestion when buffer unchanged", function()
    feed("iline1<CR>line2<CR>line3<Esc>")
    n.exec_lua([[require("kyoh86.poc.ghost")._stage_for_test(...)]], { row = 0, col = 0 }, { "ghost1", "ghost2" }, { no_preview = true })
    local res = n.exec_lua([[local ok,msg=require("kyoh86.poc.ghost").accept(); return {ok,msg}]])
    assert(res[1], res[2])
    n.command("redraw!")
    local lines = n.exec_lua([[return vim.api.nvim_buf_get_lines(0, 0, -1, false)]])
    eq({ "line1", "ghost1", "ghost2", "line2", "line3" }, lines)
  end)

  it("inserts conflict markers when buffer changed", function()
    feed("iline1<CR>line2<CR>line3<Esc>")
    n.exec_lua([[require("kyoh86.poc.ghost")._stage_for_test(...)]], { row = 0, col = 0 }, { "ghost1", "ghost2" }, { no_preview = true })
    feed("Goedited<Esc>")
    local res = n.exec_lua([[local ok,msg=require("kyoh86.poc.ghost").accept(); return {ok,msg}]])
    assert(res[1], res[2])
    n.command("redraw!")
    local lines = n.exec_lua([[return vim.api.nvim_buf_get_lines(0, 0, -1, false)]])
    eq({
      "line1",
      "<<<<<<< CURRENT",
      "line2",
      "=======",
      "ghost1",
      "ghost2",
      ">>>>>>> CODEX",
      "line3",
      "edited",
    }, lines)
  end)
end)
