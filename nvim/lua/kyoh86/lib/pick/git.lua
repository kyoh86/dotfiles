local P = require("kyoh86.lib.pick")
local M = {}

local function root()
  return vim.fs.root(vim.fn.getcwd(), ".git") or vim.fn.getcwd()
end

local function git(args, done)
  P.command(vim.list_extend({ "git", "-C", root() }, args), {}, done or function()
    vim.cmd.checktime()
  end)
end

local function preview(args)
  return function(buf, item)
    git(args(item), function(text)
      P.preview(buf, text, "diff")
    end)
  end
end

function M.status()
  local cwd = root()
  P.cli("Git status", { "git", "-C", cwd, "status", "--porcelain=v1", "-z", "--untracked-files=all" }, function(text)
    local parts, items, index = vim.split(text, "\0", { plain = true, trimempty = true }), {}, 1
    while index <= #parts do
      local status, path = parts[index]:sub(1, 2), parts[index]:sub(4)
      items[#items + 1] = { text = status .. " " .. path, path = cwd .. "/" .. path, status = status }
      index = index + (status:find("[RC]") and 2 or 1)
    end
    return items
  end, {
    choose = function(item)
      if vim.fn.filereadable(item.path) == 1 then
        P.open(item)
      end
    end,
    preview = function(buf, item)
      if item.status == "??" then
        return require("mini.pick").default_preview(buf, item)
      end
      git({ "diff", "--", item.path }, function(unstaged)
        git({ "diff", "--cached", "--", item.path }, function(staged)
          P.preview(buf, staged .. "\n" .. unstaged, "diff")
        end)
      end)
    end,
    actions = {
      {
        name = "stage",
        key = "<C-g>",
        run = function(items)
          local args = { "add", "--" }
          for _, item in ipairs(items) do
            args[#args + 1] = item.path
          end
          git(args, M.status)
        end,
      },
      {
        name = "unstage",
        key = "<C-r>",
        run = function(items)
          local args = { "reset", "--" }
          for _, item in ipairs(items) do
            args[#args + 1] = item.path
          end
          git(args, M.status)
        end,
      },
    },
  })
end

local function snapshot(item)
  local name = "git-snapshot://" .. item.commit .. "/" .. item.file
  local existing = vim.fn.bufnr(name)
  if existing >= 0 then
    vim.api.nvim_set_current_buf(existing)
    return
  end
  git({ "show", item.commit .. ":" .. item.file }, function(text)
    vim.cmd.enew()
    vim.bo.buftype, vim.bo.bufhidden, vim.bo.swapfile = "nofile", "wipe", false
    vim.api.nvim_buf_set_name(0, name)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, P.content(text))
    vim.bo.filetype = vim.filetype.match({ filename = item.file }) or ""
    vim.bo.modified, vim.bo.modifiable = false, false
  end)
end

function M.files(commit)
  P.cli("Changed files: " .. commit, { "git", "-C", root(), "diff-tree", "--root", "--no-commit-id", "--name-only", "-r", "-z", commit }, function(text)
    return vim.tbl_map(function(path)
      return { text = path, file = path, path = root() .. "/" .. path, commit = commit }
    end, vim.split(text, "\0", { plain = true, trimempty = true }))
  end, {
    choose = snapshot,
    preview = preview(function(item)
      return { "show", item.commit, "--", item.file }
    end),
    actions = { { name = "作業ツリーのファイルを開く", key = "<C-e>", run = P.each(P.open) } },
  })
end

function M.log(ref)
  local args = { "git", "-C", root(), "log", "-n", "500", "--format=%H%x09%cs%x09%an%x09%s" }
  if ref then
    args[#args + 1] = ref
  end
  args[#args + 1] = "--"
  P.cli("Git log", args, function(text)
    return vim.tbl_map(function(line)
      local hash, rest = line:match("^(%x+)\t(.*)$")
      return { text = hash:sub(1, 10) .. " " .. rest, hash = hash }
    end, P.lines(text))
  end, {
    choose = function(item)
      M.files(item.hash)
    end,
    preview = preview(function(item)
      return { "show", "--stat", "--patch", item.hash }
    end),
    actions = {
      {
        name = "hashをyank",
        key = "<C-y>",
        run = function(items)
          vim.fn.setreg(
            '"',
            table.concat(
              vim.tbl_map(function(item)
                return item.hash
              end, items),
              "\n"
            )
          )
        end,
      },
      { name = "hashを挿入", key = "<C-e>", run = P.each(function(item)
        P.insert(item.hash)
      end) },
      {
        name = "fixup commit",
        key = "<C-f>",
        run = function(items)
          git({ "commit", "--fixup=" .. items[1].hash })
        end,
      },
      {
        name = "reset --mixed",
        key = "<C-r>",
        run = function(items)
          P.confirm("Reset HEAD to " .. items[1].hash .. "?", function()
            git({ "reset", "--mixed", items[1].hash })
          end)
        end,
      },
    },
  })
end

function M.branches()
  P.cli("Git branches", { "git", "for-each-ref", "--format=%(HEAD)%09%(refname)%09%(refname:short)%09%(upstream:short)%09%(authorname)%09%(committerdate:short)", "refs/heads", "refs/remotes" }, function(text)
    local items = {}
    for _, line in ipairs(P.lines(text)) do
      local parts = vim.split(line, "\t", { plain = true })
      if not parts[3]:match("/HEAD$") then
        items[#items + 1] = { text = line, ref = parts[2], branch = parts[3], remote = parts[2]:match("^refs/remotes/") ~= nil }
      end
    end
    return items
  end, {
    choose = function(item)
      git({ "switch", item.remote and "--track" or "--", item.branch })
    end,
    preview = preview(function(item)
      return { "log", "-20", "--oneline", item.ref, "--" }
    end),
    actions = {
      {
        name = "branchを削除",
        key = "<C-d>",
        run = function(items)
          P.confirm("Delete " .. #items .. " branch(es)?", function()
            for _, item in ipairs(items) do
              if item.remote then
                local remote, branch = item.branch:match("^([^/]+)/(.+)$")
                git({ "push", remote, "--delete", branch })
              else
                git({ "branch", "-d", "--", item.branch })
              end
            end
          end)
        end,
      },
      {
        name = "選択branchから作成",
        key = "<C-b>",
        run = function(items)
          vim.ui.input({ prompt = "New branch: " }, function(name)
            if name and name ~= "" then
              git({ "switch", "-c", name, items[1].ref })
            end
          end)
        end,
      },
      {
        name = "log",
        key = "<C-l>",
        run = function(items)
          M.log(items[1].ref)
        end,
      },
      {
        name = "rebase onto",
        key = "<C-r>",
        run = function(items)
          P.confirm("Rebase onto " .. items[1].branch .. "?", function()
            git({ "rebase", items[1].ref })
          end)
        end,
      },
      {
        name = "branch名をyank",
        key = "<C-y>",
        run = function(items)
          vim.fn.setreg('"', items[1].branch)
        end,
      },
    },
  })
end

function M.setup()
  P.register("git-status", "<leader>fgs", "Git Status", M.status)
  P.register("git-branch", "<leader>fgb", "Git Branch", M.branches)
  P.register("git-log", "<leader>fgl", "Git Log", function()
    M.log()
  end)
  P.register("git-diff-tree", nil, "Commitの変更ファイル", function(opts)
    M.files(opts.commit or "HEAD")
  end)
end

return M
