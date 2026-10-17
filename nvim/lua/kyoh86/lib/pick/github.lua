local P = require("kyoh86.lib.pick")
local M = {}

local function gh(args, done)
  P.command(vim.list_extend({ "gh" }, args), {}, done or function() end)
end

local function identity(item)
  return item.url:match("^https?://[^/]+/([^/]+/[^/]+)/[^/]+/(%d+)")
end

local function view(item, edit)
  local name = "github-" .. (edit and "edit" or "view") .. "://" .. item.url
  local existing = vim.fn.bufnr(name)
  if existing >= 0 then
    vim.api.nvim_set_current_buf(existing)
    return
  end
  gh({ item.kind, "view", item.url, "--json", "title,body,url" }, function(text)
    local data = P.json(text)
    data.body = type(data.body) == "string" and data.body or ""
    vim.cmd.enew()
    local buf = vim.api.nvim_get_current_buf()
    vim.bo[buf].buftype, vim.bo[buf].bufhidden, vim.bo[buf].swapfile = edit and "acwrite" or "nofile", "hide", false
    vim.api.nvim_buf_set_name(buf, name)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, P.content(edit and data.body or ("# " .. data.title .. "\n\n" .. data.url .. "\n\n" .. data.body)))
    vim.bo[buf].filetype, vim.bo[buf].modified = "markdown", false
    if edit then
      vim.api.nvim_create_autocmd("BufWriteCmd", {
        buffer = buf,
        callback = function()
          local tick = vim.api.nvim_buf_get_changedtick(buf)
          local file = vim.fn.tempname()
          vim.fn.writefile(vim.api.nvim_buf_get_lines(buf, 0, -1, false), file)
          local ok = pcall(
            vim.system,
            { "gh", item.kind, "edit", item.url, "--body-file", file },
            { text = true },
            vim.schedule_wrap(function(result)
              vim.fn.delete(file)
              if result.code ~= 0 then
                return P.notify(result.stderr)
              end
              if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_changedtick(buf) == tick then
                vim.bo[buf].modified = false
              end
            end)
          )
          if not ok then
            vim.fn.delete(file)
            P.notify("Failed to start gh")
          end
        end,
      })
    else
      vim.bo[buf].modifiable = false
    end
  end)
end

local function link(item, full)
  local repo, number = identity(item)
  local short = repo and (repo .. "#" .. number) or item.url
  return full and (item.title .. " " .. short) or short
end

function M.issues(opts)
  opts = opts or {}
  local kind, state = opts.kind or "issue", opts.state or "open"
  local args
  if opts.my or opts.search then
    args = { "search", kind == "pr" and "prs" or "issues", "--limit", "500", "--json", "number,title,url,state,body,repository" }
    if opts.my then
      args[#args + 1], args[#args + 2] = kind == "pr" and "--author" or "--involves", "@me"
    end
    if state ~= "all" then
      args[#args + 1], args[#args + 2] = "--state", state
    end
    if opts.query and opts.query ~= "" then
      args[#args + 1] = opts.query
    end
  else
    args = { kind, "list", "--state", state, "--limit", "500", "--json", "number,title,url,state,body" }
    if opts.repo then
      args[#args + 1], args[#args + 2] = "--repo", opts.repo
    end
  end
  P.cli("GitHub " .. kind .. " (" .. state .. ")", vim.list_extend({ "gh" }, args), function(text)
    return vim.tbl_map(function(item)
      item.kind = kind
      item.body = type(item.body) == "string" and item.body or ""
      item.text = link(item) .. " [" .. item.state .. "] " .. item.title
      return item
    end, P.json(text))
  end, {
    choose = kind == "pr" and P.browse or function(item)
      view(item)
    end,
    preview = function(buf, item)
      P.preview(buf, "# " .. item.title .. "\n\n" .. (item.body or ""), "markdown")
    end,
    actions = {
      { name = "ブラウザで開く", key = "<C-b>", run = P.each(P.browse) },
      {
        name = "本文を編集 (:wで保存)",
        key = "<C-e>",
        run = function(items)
          view(items[1], true)
        end,
      },
      {
        name = "コメント",
        key = "<C-g>",
        run = function(items)
          P.terminal({ "gh", kind, "comment", items[1].url, "--editor" })
        end,
      },
      { name = "リンクを挿入", key = "<C-r>", run = P.each(function(item)
        P.insert(link(item))
      end) },
      { name = "タイトル付きリンクを挿入", key = "<C-f>", run = P.each(function(item)
        P.insert(link(item, true))
      end) },
      { name = "リンクをカーソル前に挿入", key = "<C-u>", run = P.each(function(item)
        P.insert(link(item), true)
      end) },
      { name = "タイトル付きリンクをカーソル前に挿入", run = P.each(function(item)
        P.insert(link(item, true), true)
      end) },
      {
        name = "リンクをyank",
        key = "<C-y>",
        run = function(items)
          vim.fn.setreg(
            '"',
            table.concat(
              vim.tbl_map(function(item)
                return link(item)
              end, items),
              "\n"
            )
          )
        end,
      },
      {
        name = "状態を切替 (open/closed/all)",
        key = "<C-l>",
        run = function()
          M.issues(vim.tbl_extend("force", opts, { state = ({ open = "closed", closed = "all", all = "open" })[state] }))
        end,
      },
      {
        name = "PRをcheckout",
        key = kind == "pr" and "<C-k>" or nil,
        run = function(items)
          if kind == "pr" then
            gh({ "pr", "checkout", items[1].url })
          end
        end,
      },
    },
  })
end

function M.repos(query)
  if not query then
    return vim.ui.input({ prompt = "GitHub repository query: " }, function(value)
      if value and value ~= "" then
        M.repos(value)
      end
    end)
  end
  P.cli("GitHub repositories", { "gh", "search", "repos", query, "--limit", "100", "--json", "fullName,description,url" }, function(text)
    return vim.tbl_map(function(item)
      item.text = item.fullName .. " " .. (type(item.description) == "string" and item.description or "")
      return item
    end, P.json(text))
  end, { choose = P.browse })
end

local function search(kind)
  vim.ui.input({ prompt = "GitHub query: ", default = "is:open " }, function(query)
    if query and query ~= "" then
      M.issues({ kind = kind, search = true, state = "all", query = query })
    end
  end)
end

function M.setup()
  P.register("github-repo-issues", "<leader>fghi", "GitHub Issues", function(opts)
    M.issues(opts)
  end)
  P.register("github-pulls", "<leader>fghp", "GitHub Pull Requests", function()
    M.issues({ kind = "pr" })
  end)
  P.register("github-my-issues", "<leader>fghgi", "GitHub My Issues", function()
    M.issues({ my = true })
  end)
  P.register("github-my-pulls", "<leader>fghgp", "GitHub My Pull Requests", function()
    M.issues({ kind = "pr", my = true })
  end)
  for _, kind in ipairs({ "issue", "pr" }) do
    P.register("github-search-" .. (kind == "pr" and "pulls" or "issues"), nil, "GitHub search " .. kind, function()
      search(kind)
    end)
  end
  P.register("github-repos", nil, "GitHub repositories", function()
    M.repos()
  end)
  P.register("github", "<leader>fgh", "GitHub", function()
    local items = {}
    for _, name in ipairs({ "github-repo-issues", "github-pulls", "github-my-issues", "github-my-pulls", "github-search-issues", "github-search-pulls", "github-repos" }) do
      items[#items + 1] = { text = name, run = P.registry[name].run }
    end
    P.start("GitHub", items, {
      choose = function(item)
        item.run({})
      end,
    })
  end)
  for command, topic in pairs({ DduSources = "ddu-source", DduFilters = "ddu-filter", DduKinds = "ddu-kind" }) do
    vim.api.nvim_create_user_command(command, function()
      M.repos("topic:" .. topic)
    end, { desc = "GitHub: " .. topic })
  end
end

return M
