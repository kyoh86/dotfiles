local P = require("kyoh86.lib.pick")
local M = {}

local function gogh(kind)
  local commands = {
    project = { "gogh", "list", "--format", "json", "--limit", "-1" },
    worktree = { "gogh", "worktree", "list", "--format", "json", "--limit", "-1" },
    repo = { "gogh", "repos", "--format", "json", "--limit", "-1" },
  }
  P.cli("gogh " .. kind, commands[kind], function(text)
    local entries = P.json(text)
    if not vim.islist(entries) then
      entries = { entries }
    end
    for _, item in ipairs(entries) do
      item.path = item.fullFilePath or item.fullPath or item.path
      local ref = item.spec or item.ref or item
      item.repo_name = item.repo or (ref.host and (ref.host .. "/" .. ref.owner .. "/" .. ref.name))
      item.url = item.url or (item.repo_name and ("https://" .. item.repo_name))
      item.text = (item.repo_name or item.relPath or item.path or item.url) .. (item.branch and (" (@" .. item.branch .. ")") or "")
    end
    return entries
  end, {
    choose = function(item)
      if kind == "repo" then
        P.browse(item)
      else
        vim.cmd.cd(vim.fn.fnameescape(item.path))
      end
    end,
    actions = {
      { name = "browse", key = "<C-b>", run = P.each(P.browse) },
      {
        name = "配下ファイル",
        key = "<C-f>",
        run = function(items)
          require("kyoh86.lib.pick.editor").files({ cwd = assert(items[1].path, "No local path") })
        end,
      },
      { name = "ディレクトリを開く", key = "<C-e>", run = P.each(P.open) },
      {
        name = "GitHub Issues",
        key = "<C-g>",
        run = function(items)
          require("kyoh86.lib.pick.github").issues({ repo = items[1].repo_name })
        end,
      },
      {
        name = "clone",
        key = "<C-k>",
        run = function(items)
          P.terminal({ "gogh", "clone", items[1].repo_name })
        end,
      },
    },
  })
end

local function plugins()
  local items = {}
  for name, plugin in pairs(require("lazy.core.config").plugins) do
    items[#items + 1] = { text = name .. " " .. plugin.dir, path = plugin.dir, url = plugin.url, plugin = plugin }
  end
  table.sort(items, function(a, b)
    return a.text < b.text
  end)
  P.start("Plugins", items, {
    choose = function(item)
      vim.cmd.cd(vim.fn.fnameescape(item.path))
    end,
    actions = {
      { name = "browse", key = "<C-b>", run = P.each(P.browse) },
      {
        name = "配下ファイル",
        key = "<C-f>",
        run = function(selected)
          require("kyoh86.lib.pick.editor").files({ cwd = selected[1].path })
        end,
      },
      {
        name = "設定を検索",
        key = "<C-g>",
        run = function(selected)
          local name = selected[1].plugin.name
          require("mini.pick").builtin.grep({ tool = "rg", pattern = name }, {
            source = { cwd = vim.fn.stdpath("config") },
          })
        end,
      },
      { name = "ディレクトリを開く", key = "<C-e>", run = P.each(P.open) },
    },
  })
end

local function tmux(kind)
  local format = kind == "session" and "#{session_id}\t#{session_name}\t#{session_windows}" or "#{pane_id}\t#{session_name}:#{window_index}.#{pane_index}\t#{pane_current_command}\t#{pane_title}"
  local args = kind == "session" and { "tmux", "list-sessions", "-F", format } or { "tmux", "list-panes", "-a", "-F", format }
  local function select(item)
    if kind == "session" then
      P.command({ "tmux", "switch-client", "-t", item.id }, {}, function() end)
    else
      P.command({ "tmux", "switch-client", "-t", item.id }, {}, function()
        P.command({ "tmux", "select-pane", "-t", item.id }, {}, function() end)
      end)
    end
  end
  P.cli("tmux " .. kind, args, function(text)
    return vim.tbl_map(function(line)
      return { text = line, id = line:match("^[^\t]+") }
    end, P.lines(text))
  end, { choose = select, actions = {
    { name = "選択", key = "<C-e>", run = P.each(select) },
    {
      name = "終了",
      key = "<C-d>",
      run = function(items)
        P.confirm("Kill " .. #items .. " " .. kind .. "(s)?", function()
          for _, item in ipairs(items) do
            P.command({ "tmux", "kill-" .. kind, "-t", item.id }, {}, function() end)
          end
        end)
      end,
    },
  } })
end

function M.parse_history(lines)
  local entries, pending = {}, ""
  for _, line in ipairs(lines) do
    line = line:gsub("^: %d+:%d+;", "")
    if line:sub(-1) == "\\" then
      pending = pending .. line:sub(1, -2) .. "\n"
    else
      entries[#entries + 1] = pending .. line
      pending = ""
    end
  end
  local items, seen = {}, {}
  for i = #entries, 1, -1 do
    if entries[i] ~= "" and not seen[entries[i]] then
      items[#items + 1] = { text = entries[i]:gsub("\n", " ↵ "), command = entries[i] }
      seen[entries[i]] = true
    end
  end
  return items
end

local function paste(items, target)
  if not vim.env.TMUX then
    return P.notify("tmuxの外では履歴を送れません")
  end
  local text = table.concat(
    vim.tbl_map(function(item)
      return item.command
    end, items),
    "\n"
  )
  P.command({ "tmux", "load-buffer", "-b", "mini-pick-history", "-" }, { stdin = text }, function()
    P.command({ "tmux", "paste-buffer", "-d", "-p", "-t", target, "-b", "mini-pick-history" }, {}, function()
      P.command({ "tmux", "select-pane", "-t", target }, {}, function() end)
    end)
  end)
end

function M.history(opts)
  opts = opts or {}
  local buf = vim.api.nvim_get_current_buf()
  local items = M.parse_history(vim.fn.readfile(vim.env.HISTFILE or vim.fn.expand("~/.zsh_history")))
  P.start("Zsh history", items, {
    choose = function(item)
      if opts.target then
        paste({ item }, opts.target)
      elseif vim.bo[buf].buftype == "terminal" then
        local channel = vim.b[buf].terminal_job_id
        vim.api.nvim_chan_send(channel, item.command)
        vim.cmd.startinsert()
      else
        P.insert(item.command)
      end
    end,
    actions = { {
      name = "tmuxに貼り付け",
      key = "<C-y>",
      run = function(selected)
        paste(selected, opts.target or "!")
      end,
    } },
  })
end

function M.start_tmux(target)
  require("kyoh86.lib.tmux").focus_nvim_pane()
  require("lazy").load({ plugins = { "mini.pick" } })
  M.history({ target = target })
end

local function emoji(slug)
  local file = assert(vim.api.nvim_get_runtime_file("data/pick-emoji.json", false)[1])
  local items = vim.json.decode(table.concat(vim.fn.readfile(file), "\n"))
  for _, item in ipairs(items) do
    item.text = item.emoji .. "  :" .. item.slug .. ":"
  end
  P.start("Emoji" .. (slug and " slug" or ""), items, {
    choose = function(item)
      P.insert(slug and (":" .. item.slug .. ":") or item.emoji)
    end,
  })
end

function M.setup()
  P.register("aws-profile", "<leader>fap", "AWS プロファイル", function()
    P.cli("AWS profiles", { "aws", "configure", "list-profiles" }, nil, {
      choose = function(item)
        vim.env.AWS_PROFILE = item
        vim.notify("AWS_PROFILE=" .. item)
      end,
    })
  end)
  for kind, suffix in pairs({ project = "l", worktree = "w", repo = "r" }) do
    P.register("gogh-" .. kind, "<leader>fp" .. suffix, "gogh " .. kind, function()
      gogh(kind)
    end)
  end
  P.register("lazy_nvim", "<leader><leader>p", "lazy.nvim プラグイン", plugins)
  P.register("tmux-session", "<leader>fts", "tmux セッション", function()
    tmux("session")
  end)
  P.register("tmux-pane", "<leader>ftp", "tmux ペイン", function()
    tmux("pane")
  end)
  P.register("zsh_history", "<C-x>y", "Zsh History", M.history, "t")
  vim.keymap.set("t", "<C-x><C-y>", function()
    M.history()
  end, { desc = "[pick] Zsh History" })
  P.register("zsh_history_tmux", nil, "Zsh History → tmux", function(opts)
    M.history({ target = opts.target or "!" })
  end)
  P.register("emoji-emoji", "<leader>fee", "絵文字", function()
    emoji(false)
  end)
  P.register("emoji-slug", "<leader>fes", "絵文字slug", function()
    emoji(true)
  end)
end

return M
