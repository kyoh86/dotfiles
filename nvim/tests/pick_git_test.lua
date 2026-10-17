-- Git actions run only in a disposable repository, never in the dotfiles repo.
local config = vim.fn.fnamemodify("nvim", ":p")
vim.opt.rtp:prepend(config)
vim.opt.rtp:prepend(vim.env.NVIM_PICK_PATH or (vim.fn.stdpath("data") .. "/lazy/mini.pick"))
local root = vim.fn.tempname()
vim.fn.mkdir(root .. "/nested", "p")
local errors = {}
vim.notify = function(message, level)
  if level == vim.log.levels.ERROR then
    errors[#errors + 1] = tostring(message)
  end
end
local function git(args)
  local argv = { "git", "-C", root, "-c", "core.hooksPath=/dev/null", "-c", "commit.gpgsign=false", "-c", "user.name=Picker Test", "-c", "user.email=picker@example.invalid" }
  vim.list_extend(argv, args)
  local result = vim.system(argv, { text = true }):wait()
  assert(result.code == 0, result.stderr)
  return result.stdout
end

local function check()
  git({ "init", "--quiet" })
  local filename = "file with spaces;literal.txt"
  vim.fn.writefile({ "first", "", "last" }, root .. "/" .. filename)
  git({ "add", "--", filename })
  git({ "commit", "--quiet", "-m", "fixture" })
  vim.fn.writefile({ "changed", "", "last" }, root .. "/" .. filename)
  vim.cmd.cd(vim.fn.fnameescape(root .. "/nested"))
  local P = require("kyoh86.lib.pick")
  local captured
  P.start = function(name, items, opts)
    captured = { name = name, opts = opts, items = nil }
    items(function(values)
      captured.items = values
    end)
  end
  local function wait_for(predicate)
    assert(vim.wait(3000, predicate), table.concat(errors, "\n"))
    assert(#errors == 0, table.concat(errors, "\n"))
  end
  local G = require("kyoh86.lib.pick.git")
  G.status()
  wait_for(function()
    return captured.items ~= nil
  end)
  assert(captured.items[1].path == root .. "/" .. filename, "status from a subdirectory must resolve repo-root paths")
  local stage
  for _, action in ipairs(captured.opts.actions) do
    if action.key == "<C-g>" then
      stage = action
    end
  end
  local items = captured.items
  captured.items = nil
  stage.run(items)
  wait_for(function()
    return captured.items and captured.items[1].status:sub(1, 1) == "M"
  end)
  assert(git({ "diff", "--cached", "--numstat" }):match("1\t1\t"))
  local unstage
  for _, action in ipairs(captured.opts.actions) do
    if action.key == "<C-r>" then
      unstage = action
    end
  end
  items = captured.items
  captured.items = nil
  unstage.run(items)
  wait_for(function()
    return captured.items and captured.items[1].status == " M"
  end)
  assert(git({ "diff", "--cached", "--name-only" }) == "")

  G.files("HEAD")
  wait_for(function()
    return captured.items ~= nil
  end)
  assert(captured.items[1].file == filename)
  captured.opts.choose(captured.items[1])
  wait_for(function()
    return vim.api.nvim_buf_get_name(0):match("^git%-snapshot://") ~= nil
  end)
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "first", "", "last" }))
  assert(not vim.bo.modifiable, "historical snapshots must be read-only")
  print("PASS: real Git in a temporary repo; subdirectory paths, stage/unstage, historical snapshot with blank lines")
end

local ok, err = xpcall(check, debug.traceback)
vim.cmd.cd("/tmp")
vim.fn.delete(root, "rf")
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd.cquit()
end
vim.cmd("qa!")
