--- LSPの状態をlua tableとして表示する

local function trim_status(client)
  local config = {}
  for key, value in pairs(client["config"]) do
    if key == "_on_attach" then
      goto continue
    elseif type(value) == "function" then
      goto continue
    else
      config[key] = value
    end
    ::continue::
  end
  return vim.tbl_extend(
    "force",
    {
      id = client["id"],
    },
    client,
    {
      config = config,
    }
  )
end

local function get_active_client_by_name(name)
  --- 指定した名前のActive Clientを取得する
  for _, client in pairs(vim.lsp.get_clients()) do
    if client["name"] == name then
      return client
    end
  end
  return nil
end

local function select_active_client()
  --- ユーザーにActive Clientの選択を迫る
  local clients = {}
  local selection = { "Select language server client: " }
  local names = {}
  for index, client in ipairs(vim.lsp.get_clients()) do
    clients[client["name"]] = client
    table.insert(selection, index .. ": " .. client["name"])
    table.insert(names, client["name"])
  end

  if #names == 0 then
    return nil
  elseif #names == 1 then
    return clients[names[1]]
  else
    local num = vim.fn.inputlist(selection)
    return clients[names[num]]
  end
end

local BUF_NAME = "[Lsp Status]"
local BUF_NAME_ESCAPED = "^\\[Lsp Status\\]$"

local function show_message(name, content)
  local buf = vim.fn.bufnr(BUF_NAME_ESCAPED, false)
  if buf == nil or buf == -1 then
    buf = vim.api.nvim_create_buf(false, true)
    local au = require("kyoh86.lib.autocmd")
    local group = au.buf_group(buf, "kyoh86.conf.lsp_stat", true)
    group:hook("BufWinLeave", {
      once = true,
      callback = function()
        group:hook("CursorHold", {
          once = true,
          command = buf .. "bwipeout!",
        })
      end,
    })
  end

  local count = vim.api.nvim_buf_line_count(buf)
  vim.api.nvim_buf_set_lines(buf, 0, count, false, vim.split(content, "\n"))
  vim.api.nvim_buf_set_name(buf, name)

  local winnr = vim.fn.bufwinnr(buf)
  if winnr == -1 then
    vim.cmd({ cmd = "split", mods = { split = "belowright" } })
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
  else
    vim.fn.win_execute(winnr, ":edit!")
  end
end

local function stringify(obj)
  -- return vim.fn.json_encode(obj) -- JSON cannot express lua table contains positive integer keys and string keys.
  return vim.inspect(obj, { depth = 10 })
end

local function show_stat(client)
  if not client then
    vim.api.nvim_echo({ { "client is not found" } }, true, { err = true })
  else
    show_message(BUF_NAME, stringify(trim_status(client)))
  end
end

--- Show status of a LSP
local function show_one(name)
  show_stat(get_active_client_by_name(name))
end

local function show_selected()
  show_stat(select_active_client())
end

--- Show statuses of all LSPs (include not activated)
local function show_all()
  show_message(
    BUF_NAME,
    stringify(vim.tbl_map(function(client)
      return trim_status(client)
    end, vim.lsp.get_clients()))
  )
end

vim.api.nvim_create_user_command("LspStat", function(t)
  if #t.fargs > 0 then
    show_one(t.fargs[1])
  else
    show_selected()
  end
end, { nargs = "?", desc = "show a LSP status" })

vim.api.nvim_create_user_command("LspStatActive", show_all, { desc = "show active LSP statuses" })
