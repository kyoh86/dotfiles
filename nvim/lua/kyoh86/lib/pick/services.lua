local P = require("kyoh86.lib.pick")
local M = {}

local function command(service, resource)
  return { "python3", assert(vim.api.nvim_get_runtime_file("scripts/pick_services.py", false)[1]), service, resource }
end

local function open_uri(item)
  vim.cmd.edit(vim.fn.fnameescape(item.path))
end

local function docbase(template)
  P.cli("DocBase " .. (template and "templates" or "posts"), command("docbase", template and "templates" or "posts"), function(text)
    return vim.tbl_map(function(post)
      local params = "domain=wacul&" .. (template and "template=" or "postId=") .. post.id
      return {
        text = (post.updated_at or post.created_at or "") .. " " .. post.title,
        path = "docbase://" .. (template and "new-post;" or "post;") .. params,
        url = post.url or ("https://wacul.docbase.io/posts/" .. post.id),
        body = post.body,
      }
    end, P.json(text))
  end, {
    choose = open_uri,
    preview = function(buf, item)
      P.preview(buf, item.body or "", "markdown")
    end,
    actions = { { name = "browse", key = "<C-b>", run = P.each(P.browse) } },
  })
end

function M.inkdrop_notes(filter)
  filter = filter or {}
  P.cli("Inkdrop notes", command("inkdrop", "notes"), function(text)
    local entries = {}
    for _, note in ipairs(P.json(text)) do
      if (not filter.book or filter.book == note.bookId) and (not filter.tag or vim.list_contains(note.tags or {}, filter.tag)) and (not filter.status or filter.status == (note.status or "none")) and (not filter.pinned or note.pinned) then
        entries[#entries + 1] = {
          text = note.title or "(untitled)",
          path = "inkdrop://note;noteId=" .. note._id,
          body = note.body,
        }
      end
    end
    return entries
  end, {
    choose = open_uri,
    preview = function(buf, item)
      P.preview(buf, item.body or "", "markdown")
    end,
  })
end

local function inkdrop_metadata(kind)
  local buf = vim.api.nvim_get_current_buf()
  local actions = { {
    name = kind == "books" and "現在のノートを移動" or "現在のノートにタグ追加",
    key = "<C-g>",
    run = function(items)
      vim.fn[kind == "books" and "inkdrop#move_note_to_book_with_id" or "inkdrop#add_tag"](items[1].id, buf)
    end,
  } }
  if kind == "tags" then
    actions[#actions + 1] = {
      name = "現在のノートからタグ削除",
      key = "<C-d>",
      run = function(items)
        vim.fn["inkdrop#remove_tag"](items[1].id, buf)
      end,
    }
  end
  P.cli("Inkdrop " .. kind, command("inkdrop", kind), function(text)
    return vim.tbl_map(function(entry)
      return { text = entry.name, id = entry._id }
    end, P.json(text))
  end, {
    choose = function(item)
      M.inkdrop_notes({ [kind == "books" and "book" or "tag"] = item.id })
    end,
    actions = actions,
  })
end

local function statuses()
  local buf = vim.api.nvim_get_current_buf()
  local items = {
    { text = "All notes", filter = {} },
    { text = "Pinned notes", filter = { pinned = true } },
  }
  for _, status in ipairs({ "none", "active", "onHold", "completed", "dropped" }) do
    items[#items + 1] = { text = status, filter = { status = status } }
  end
  P.start("Inkdrop status", items, {
    choose = function(item)
      M.inkdrop_notes(item.filter)
    end,
    actions = { {
      name = "現在のノートのstatus変更",
      key = "<C-g>",
      run = function(selected)
        if selected[1].filter.status then
          vim.fn["inkdrop#set_status"](selected[1].filter.status, buf)
        end
      end,
    } },
  })
end

local function zenn()
  local cwd = vim.fn.getcwd()
  local items = {}
  for _, path in ipairs(vim.fn.globpath(cwd .. "/articles", "*.md", false, true)) do
    local meta = {}
    for _, line in ipairs(vim.fn.readfile(path, "", 50)) do
      local key, value = line:match("^([%w_]+):%s*(.*)$")
      if key then
        if value:sub(1, 1) == '"' then
          local ok, decoded = pcall(vim.json.decode, value)
          value = ok and decoded or value
        elseif value:sub(1, 1) == "'" then
          value = value:sub(2, -2):gsub("''", "'")
        end
        meta[key] = value
      end
    end
    local slug = vim.fn.fnamemodify(path, ":t:r")
    local stat = vim.uv.fs_stat(path)
    items[#items + 1] = {
      text = os.date("%Y-%m-%d", stat.mtime.sec) .. " " .. (meta.emoji or "") .. " " .. (meta.title or slug) .. " " .. slug,
      path = path,
      url = "http://localhost:8000/articles/" .. slug,
    }
  end
  table.sort(items, function(a, b)
    return a.text > b.text
  end)
  P.start("Zenn articles", items, { actions = { { name = "ローカルプレビュー", key = "<C-b>", run = P.each(P.browse) } } })
end

function M.setup()
  P.register("docbase_posts", "<leader>fdp", "DocBase Posts", function()
    docbase(false)
  end)
  P.register("docbase_templates", "<leader>fdt", "DocBase Templates", function()
    docbase(true)
  end)
  P.register("inkdrop_note", "<leader>fin", "Inkdrop Notes", M.inkdrop_notes)
  P.register("inkdrop_book", "<leader>fib", "Inkdrop Books", function()
    inkdrop_metadata("books")
  end)
  P.register("inkdrop_tag", "<leader>fit", "Inkdrop Tags", function()
    inkdrop_metadata("tags")
  end)
  P.register("inkdrop_status", "<leader>fis", "Inkdrop Status", statuses)
  P.register("zenn-dev-article", "<leader>fza", "Zenn.dev記事", zenn)
end

return M
