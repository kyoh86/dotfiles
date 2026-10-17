-- Read-only source fixtures. No external API calls or real actions are executed.
vim.opt.rtp:prepend(vim.fn.fnamemodify("nvim", ":p"))
local lazy = vim.fn.stdpath("data") .. "/lazy/"
vim.opt.rtp:prepend(vim.env.NVIM_PICK_PATH or (lazy .. "mini.pick"))
vim.opt.rtp:prepend(vim.env.NVIM_EXTRA_PATH or (lazy .. "mini.extra"))

local function check()
  local P = require("kyoh86.lib.pick")
  require("mini.pick").setup()
  P.setup()
  local captured, commands = {}, {}
  P.start = function(name, items, opts)
    captured = { name = name, opts = opts or {} }
    if type(items) == "function" then
      items(function(values)
        captured.items = values
      end)
    else
      captured.items = items
    end
  end
  P.command = function(argv, _, callback)
    commands[#commands + 1] = argv
    local text
    if argv[1] == "aws" then
      text = "first\nsecond\n"
    elseif argv[1] == "gogh" then
      if argv[2] == "worktree" then
        text = vim.json.encode({ repo = "github.com/owner/repo", branch = "main", path = "/tmp/repo" }) .. "\n"
      elseif argv[2] == "repos" then
        text = vim.json.encode({ spec = { host = "github.com", owner = "owner", name = "repo" }, url = "https://github.com/owner/repo" }) .. "\n"
      else
        text = vim.json.encode({ fullPath = "/tmp/repo", path = "github.com/owner/repo", host = "github.com", owner = "owner", name = "repo" }) .. "\n"
      end
    elseif argv[1] == "gh" then
      if vim.list_contains(argv, "repos") then
        text = vim.json.encode({ { fullName = "owner/repo", description = vim.NIL, url = "https://github.com/owner/repo" } })
      else
        text = vim.json.encode({ { number = 1, title = "Fixture", url = "https://github.com/owner/repo/issues/1", state = "open", body = vim.NIL } })
      end
    elseif argv[1] == "tmux" then
      text = "$1\tsession\t1\n"
    elseif argv[1] == "python3" then
      if argv[3] == "docbase" then
        text = vim.json.encode({ { id = 1, title = "post", body = "body" } })
      elseif argv[4] == "notes" then
        text = vim.json.encode({ { _id = "note:1", title = "note", body = "body", bookId = "book:1", tags = { "tag:1" }, status = "active" } })
      else
        text = vim.json.encode({ { _id = "book:1", name = "fixture" } })
      end
    elseif argv[1] == "git" then
      if vim.list_contains(argv, "status") then
        text = "R  new name.txt\0old name.txt\0?? untracked.txt\0"
      elseif vim.list_contains(argv, "for-each-ref") then
        text = "*\trefs/heads/main\tmain\torigin/main\tAuthor\t2026-10-18\n"
      elseif vim.list_contains(argv, "diff-tree") then
        text = "nested/file name.txt\0"
      else
        text = "abcdef123456\t2026-10-18\tAuthor\tSubject\n"
      end
    else
      error("Unexpected command: " .. vim.inspect(argv))
    end
    callback(text)
  end
  vim.ui.input = function(_, on_input)
    on_input("fixture")
  end
  local count = 0
  for _, name in ipairs({
    "aws-profile",
    "gogh-project",
    "gogh-worktree",
    "gogh-repo",
    "tmux-session",
    "tmux-pane",
    "github-repo-issues",
    "github-pulls",
    "github-my-issues",
    "github-my-pulls",
    "github-search-issues",
    "github-search-pulls",
    "github-repos",
    "docbase_posts",
    "docbase_templates",
    "inkdrop_note",
    "inkdrop_book",
    "inkdrop_tag",
    "inkdrop_status",
    "git-status",
    "git-branch",
    "git-log",
    "git-diff-tree",
  }) do
    P.registry[name].run({})
    assert(captured.items and #captured.items > 0, name .. " returned no fixture items")
    local used = {}
    for _, action in ipairs(captured.opts.actions or {}) do
      if action.key then
        local chord = vim.keycode(action.key)
        assert(not used[chord], name .. ": duplicate chord " .. action.key)
        assert(action.key:match("^<C%-"), name .. ": action must use Ctrl")
        assert(chord ~= vim.keycode("<Tab>") and chord ~= vim.keycode("<CR>"), name .. ": terminal alias collision")
        used[chord] = true
      end
    end
    if name == "git-status" then
      assert(#captured.items == 2 and captured.items[1].path:match("new name.txt$"), "rename parsing consumed another status entry")
    elseif name == "gogh-project" then
      assert(captured.items[1].path == "/tmp/repo", "single-object NDJSON must work")
    elseif name == "docbase_templates" then
      assert(captured.items[1].path == "docbase://new-post;domain=wacul&template=1")
    end
    count = count + 1
  end
  local Pservices = require("kyoh86.lib.pick.services")
  Pservices.inkdrop_notes({ book = "missing" })
  assert(#captured.items == 0, "Inkdrop book filter must exclude other notes")
  Pservices.inkdrop_notes({ tag = "tag:1", status = "active" })
  assert(#captured.items == 1)
  print("PASS: " .. count .. " source fixtures; Ctrl chord checks, Git renames, gogh NDJSON, Inkdrop filters, service URIs")
end

local ok, err = xpcall(check, debug.traceback)
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd.cquit()
end
vim.cmd("qa!")
