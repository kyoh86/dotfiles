vim.opt.rtp:prepend(vim.fn.fnamemodify("nvim", ":p"))
local P = require("kyoh86.lib.pick")
local repo = "https://github.com/owner/repo/issues/"
local temp = vim.fn.tempname()

local function check()
  local requests, writes = {}, {}
  P.command = function(argv, opts, done)
    requests[#requests + 1] = { argv = argv, opts = opts }
    local number = tonumber(argv[4]:match("%d+$"))
    done(vim.json.encode({
      number = number,
      title = "Test Issue",
      url = repo .. number,
      state = "OPEN",
      body = "Body",
      comments = {
        { author = { login = "user" }, createdAt = "2026-10-01", url = repo .. number .. "#issuecomment-42", body = "Comment" },
      },
    }))
  end
  local fail = false
  vim.system = function(argv, opts)
    writes[#writes + 1] = { argv = argv, opts = opts }
    return {
      wait = function()
        return fail and { code = 1, stderr = "denied" } or { code = 0 }
      end,
    }
  end
  require("kyoh86.lib.tmux").focus_nvim_pane = function() end
  vim.cmd.runtime("lua/kyoh86/conf/open_buffer.lua")
  vim.cmd.runtime("lua/kyoh86/conf/github.lua")
  P.terminal = function(argv)
    assert(vim.deep_equal(argv, { "gh", "auth", "login" }))
  end
  vim.cmd.GitHubLogin()

  local function map(key)
    local callback = vim.fn.maparg(key, "n", false, true).callback
    assert(callback, "No mapping for " .. key)
    callback()
  end
  local function reference(text, key)
    vim.cmd.enew()
    vim.api.nvim_set_current_line(text)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    map(key)
  end

  reference("#12", "gf")
  assert(requests[1].argv[4] == "12")
  assert(requests[1].opts.cwd == vim.fn.getcwd())
  assert(#vim.api.nvim_tabpage_list_wins(0) == 1)
  reference("owner/repo#13.", "gfv")
  assert(requests[2].argv[4] == "13" and requests[2].argv[6] == "owner/repo")
  assert(#vim.api.nvim_tabpage_list_wins(0) == 2)
  assert(vim.api.nvim_win_get_position(0)[2] == 0)
  reference("#14", "gfx")
  assert(#vim.api.nvim_tabpage_list_wins(0) == 3)
  assert(vim.api.nvim_win_get_position(0)[1] == 0)
  map("<leader>n")
  assert(requests[#requests].argv[4] == "15")
  map("<leader>p")
  assert(requests[#requests].argv[4] == "14")

  local viewer = vim.api.nvim_get_current_buf()
  map("<leader>e")
  vim.api.nvim_set_current_line("Updated body")
  fail = true
  local ok, err = pcall(vim.cmd.write)
  assert(not ok and tostring(err):find("denied", 1, true))
  assert(vim.bo.modified and vim.api.nvim_get_current_line() == "Updated body")
  fail = false
  vim.cmd.write()
  assert(not vim.bo.modified)
  assert(writes[#writes].argv[3] == "edit" and writes[#writes].opts.stdin == "Updated body")

  vim.api.nvim_set_current_buf(viewer)
  vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(viewer), 0 })
  local browse
  P.browse = function(item)
    browse = item.url
  end
  map("<leader>b")
  assert(browse == repo .. "14#issuecomment-42")
  map("<leader>e")
  vim.api.nvim_set_current_line("Updated comment")
  vim.cmd.write()
  assert(writes[#writes].argv[7] == "repos/owner/repo/issues/comments/42")
  assert(vim.json.decode(writes[#writes].opts.stdin).body == "Updated comment")

  vim.api.nvim_set_current_buf(viewer)
  map("<leader>c")
  vim.api.nvim_set_current_line("New comment")
  vim.cmd.write()
  assert(writes[#writes].argv[3] == "comment" and writes[#writes].opts.stdin == "New comment")

  local root = temp .. "/zenn"
  vim.fn.mkdir(root .. "/articles", "p")
  vim.fn.writefile({ '{"devDependencies":{"zenn-cli":"*"}}' }, root .. "/package.json")
  local plugin = vim.env.NVIM_ZENN_AUTOCMD_PATH or (vim.fn.stdpath("data") .. "/lazy/vim-zenn-autocmd")
  vim.opt.rtp:prepend(plugin)
  vim.cmd.cd(root)
  require("kyoh86.plug.zenn_dev")[1].config()
  assert(vim.fn.exists(":ZennDevNewArticle") == 2)
  vim.cmd.ZennDevNewArticle()
  local random = vim.api.nvim_buf_get_name(0)
  assert(vim.fs.basename(random):match("^[0-9a-f]+%.md$"))
  local draft = vim.fn.readfile(random)
  assert(vim.list_contains(draft, 'emoji: "🐼"') and vim.list_contains(draft, "published: false"))
  vim.cmd.ZennDevNewArticle({ args = { "--slug=sample-article", "--title=Quoted title", "--type=idea", "--published", "--publication-name=team" } })
  local path = root .. "/articles/sample-article.md"
  local lines = vim.fn.readfile(path)
  assert(vim.list_contains(lines, 'title: "Quoted title"'))
  assert(vim.list_contains(lines, 'type: "idea"') and vim.list_contains(lines, 'publication_name: "team"'))
  assert(vim.list_contains(lines, "published: true"))
  assert(not pcall(vim.cmd.ZennDevNewArticle, { args = { "--slug=sample-article", "--title=overwrite" } }))
  assert(vim.deep_equal(lines, vim.fn.readfile(path)))
  vim.cmd.cd(temp)
  assert(vim.fn.exists(":ZennDevNewArticle") == 0)
  print("PASS: GitHub cursor navigation and writes; Zenn repository activation and exclusive creation")
end

local ok, err = xpcall(check, debug.traceback)
vim.fn.delete(temp, "rf")
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd.cquit()
end
vim.cmd("qa!")
