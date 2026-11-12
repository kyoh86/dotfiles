local cwd = vim.fn.getcwd()
vim.opt.rtp:prepend(cwd .. "/nvim")
local temp = vim.fn.tempname()

local function check()
  vim.cmd.runtime("lua/kyoh86/conf/mdlink.lua")
  vim.cmd.runtime("lua/kyoh86/conf/qftable.lua")
  vim.cmd.runtime("lua/kyoh86/conf/zsh_history.lua")
  vim.cmd.runtime("lua/kyoh86/conf/tomlvsnip.lua")

  local getreg, system = vim.fn.getreg, vim.system
  vim.fn.getreg = function(reg)
    if reg == "*" then
      return ""
    end
    assert(reg == "+")
    return "https://example.test/(a)"
  end
  local response
  vim.system = function(args, _, callback)
    assert(args[2] == "title")
    response = callback
    return {}
  end
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_set_current_line("先後")
  vim.api.nvim_win_set_cursor(0, { 1, #"先" })
  vim.cmd.MarkdownUrlPaste()
  vim.cmd.enew()
  response({ code = 0, stdout = "a [b]" })
  assert(vim.wait(1000, function()
    return vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "先[a \\[b\\]](https://example.test/\\(a\\))後"
  end))
  assert(vim.api.nvim_get_current_buf() ~= buf and vim.api.nvim_get_current_line() == "")
  vim.cmd.MarkdownUrlPaste()
  response({ code = 1 })
  assert(vim.wait(1000, function()
    return vim.api.nvim_get_current_line() == "https://example.test/(a)"
  end))
  vim.fn.getreg, vim.system = getreg, system

  vim.fn.setqflist({ { filename = "file.lua", lnum = 4, text = "日本語 | test\nnext" } })
  vim.cmd.QfTable({ args = { "--column=lnum", "--column=text", "--output=reg:a" } })
  local rows = vim.fn.getreg("a", 1, true)
  assert(#rows == 3 and rows[2]:match("^| %-%-%-"))
  assert(rows[3]:find("日本語 \\| test<br>next", 1, true))
  vim.fn["qftable#show"]({ columns = { "bufname" }, printer = "cur" })
  assert(vim.api.nvim_buf_get_lines(0, 3, 4, false)[1]:find("file.lua", 1, true))

  vim.fn.mkdir(temp, "p")
  local history = temp .. "/.zsh_history"
  local prefix = ": 1000:0;echo "
  local original = prefix .. "🐼"
  local encoded = prefix .. "\240\131\191\131\176\188"
  local function put(path, data)
    local file = assert(io.open(path, "wb"))
    assert(file:write(data))
    assert(file:close())
  end
  local function bytes(path)
    local file = assert(io.open(path, "rb"))
    local data = assert(file:read("*a"))
    file:close()
    return data
  end
  put(history, encoded .. "\n")
  vim.uv.fs_chmod(history, 384)
  vim.cmd.edit(history)
  assert(vim.api.nvim_get_current_line() == original, vim.inspect(vim.api.nvim_get_current_line()))
  assert(vim.bo.endofline and vim.bo.buftype == "acwrite")
  vim.api.nvim_set_current_line(original .. " x")
  put(history .. ".LOCK", "")
  assert(not pcall(vim.cmd.write) and vim.bo.modified)
  assert(bytes(history) == encoded .. "\n")
  assert(vim.uv.fs_unlink(history .. ".LOCK"))
  vim.cmd.write()
  assert(bytes(history) == encoded .. " x\n")
  assert(bit.band(vim.uv.fs_stat(history).mode, 511) == 384)
  assert(not vim.bo.modified)
  vim.api.nvim_set_current_line("local edit")
  put(history, encoded .. " external\n")
  assert(not pcall(vim.cmd.write) and vim.bo.modified)
  assert(vim.api.nvim_get_current_line() == "local edit")
  assert(bytes(history) == encoded .. " external\n")
  vim.cmd("edit!")
  assert(vim.api.nvim_get_current_line() == original .. " external")

  vim.env.XDG_CONFIG_HOME = cwd
  local primary, secondary = temp .. "/primary", temp .. "/secondary"
  vim.fn.mkdir(primary)
  vim.fn.mkdir(secondary)
  vim.g.vsnip_snippet_dir = primary
  vim.g.vsnip_snippet_dirs = { secondary }
  put(primary .. "/lua.toml", "[base]\nprefix = 'b'\nbody = ['base']\n")
  put(secondary .. "/extra.lua.toml", "[other]\nprefix = 'o'\nbody = 'other'\n")
  local shard = primary .. "/part.lua.toml"
  vim.cmd.edit(shard)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "[part]", "prefix = 'p'", "body = 'first'" })
  vim.cmd.write()
  local json = primary .. "/lua.json"
  local snippets = vim.json.decode(bytes(json))
  assert(snippets.base.body[1] == "base" and snippets.other.body == "other" and snippets.part.body == "first")
  vim.cmd.edit(json)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { '{"latest":{"prefix":"latest","body":["unsaved"]}}' })
  vim.cmd.DeconvertToTOML()
  assert(bytes(primary .. "/lua.toml"):find("unsaved", 1, true))
  print("PASS: Markdown paste, Quickfix table, zsh history protection, and Neovim snippet round trip")
end

local ok, err = xpcall(check, debug.traceback)
vim.fn.delete(temp, "rf")
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd.cquit()
end
vim.cmd("qa!")
