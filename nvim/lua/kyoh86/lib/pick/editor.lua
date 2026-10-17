local P = require("kyoh86.lib.pick")
local M = {}

local function extra(name, local_opts, opts)
  return require("mini.extra").pickers[name](local_opts or {}, opts)
end

function M.files(opts)
  opts = opts or {}
  return require("mini.pick").builtin.files({ tool = "rg" }, P.options("Files", nil, { cwd = opts.cwd }))
end

function M.grep(opts)
  opts = opts or {}
  -- Live grep reserves C-o for globs; other lists use it for actions.
  return require("mini.pick").builtin.grep_live({ tool = "rg" }, { source = { cwd = opts.cwd } })
end

local function buffers()
  local items = {}
  for _, buf in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if vim.bo[buf.bufnr].buftype ~= "quickfix" then
      local title = vim.b[buf.bufnr].term_title or buf.name
      items[#items + 1] = {
        text = (buf.changed == 1 and "+ " or "  ") .. buf.bufnr .. " " .. (title ~= "" and title or "[No Name]"),
        bufnr = buf.bufnr,
        lnum = math.max(buf.lnum, 1),
      }
    end
  end
  P.start("Buffers", items, { actions = { {
    name = "バッファを閉じる",
    key = "<C-d>",
    run = P.each(function(item)
      vim.api.nvim_buf_delete(item.bufnr, { force = false })
    end),
  } } })
end

local function quickfix_history()
  local items = {}
  for nr = 1, vim.fn.getqflist({ nr = "$" }).nr do
    local list = vim.fn.getqflist({ nr = nr, title = 1, size = 1, id = 0 })
    items[#items + 1] = { text = nr .. " " .. list.title .. " (" .. list.size .. ")", nr = nr, id = list.id }
  end
  P.start("Quickfix history", items, {
    choose = function(item)
      local current = vim.fn.getqflist({ nr = 0 }).nr
      if item.nr < current then
        vim.cmd.colder({ count = current - item.nr })
      elseif item.nr > current then
        vim.cmd.cnewer({ count = item.nr - current })
      end
      extra("list", { scope = "quickfix" })
    end,
    preview = function(buf, item)
      local list = vim.fn.getqflist({ id = item.id, items = 1 }).items
      P.preview(
        buf,
        vim.tbl_map(function(entry)
          return vim.fn.bufname(entry.bufnr) .. ":" .. entry.lnum .. " " .. entry.text
        end, list)
      )
    end,
  })
end

local function history(kind)
  local items = vim.fn["mr#" .. kind .. "#list"]()
  P.start(kind, items, { choose = kind == "mrr" and function(path)
    vim.cmd.cd(vim.fn.fnameescape(path))
  end or nil, actions = { {
    name = "履歴から削除",
    key = "<C-d>",
    run = P.each(function(path)
      vim.fn["mr#" .. kind .. "#delete"](path)
    end),
  } } })
end

local function lsp_clients()
  local items = {}
  for _, client in ipairs(vim.lsp.get_clients()) do
    items[#items + 1] = { text = client.id .. " " .. client.name .. " " .. (client.root_dir or ""), client = client }
  end
  local function stop(force)
    return P.each(function(item)
      item.client:stop(force)
    end)
  end
  P.start("LSP clients", items, {
    choose = function(item)
      vim.print(require("kyoh86.lib.lsp_client").get_convertible_clients())
    end,
    actions = {
      { name = "停止", key = "<C-d>", run = stop(false) },
      { name = "強制停止", key = "<C-k>", run = stop(true) },
      { name = "再起動", key = "<C-r>", run = P.each(function(item)
        vim.cmd("lsp restart " .. item.client.name)
      end) },
    },
  })
end

local function definitions()
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local methods = {
    { "textDocument/definition", "def" },
    { "textDocument/typeDefinition", "type" },
    { "textDocument/declaration", "decl" },
    { "textDocument/implementation", "impl" },
  }
  P.start("LSP definitions", function(update)
    local items = {}
    for _, method in ipairs(methods) do
      vim.lsp.buf_request_all(buf, method[1], function(client)
        return vim.lsp.util.make_position_params(win, client.offset_encoding)
      end, function(results)
        for id, result in pairs(results) do
          local client = vim.lsp.get_client_by_id(id)
          if result.result and client then
            local locations = result.result
            if locations.uri or locations.targetUri then
              locations = { locations }
            end
            for _, entry in ipairs(vim.lsp.util.locations_to_items(locations, client.offset_encoding)) do
              items[#items + 1] = {
                text = method[2] .. " " .. entry.filename .. ":" .. entry.lnum .. " " .. entry.text,
                path = entry.filename,
                lnum = entry.lnum,
                col = entry.col,
              }
            end
          end
        end
        update(vim.deepcopy(items))
      end)
    end
  end)
end

local function outgoing_calls()
  local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  local function calls(item, client)
    client:request("callHierarchy/outgoingCalls", { item = item }, function(err, result)
      if err then
        return P.notify(err.message)
      end
      local entries = {}
      for _, call in ipairs(result or {}) do
        local location = vim.lsp.util.locations_to_items({ { uri = call.to.uri, range = call.to.selectionRange } }, client.offset_encoding)[1]
        entries[#entries + 1] = {
          text = call.to.name .. " " .. location.filename .. ":" .. location.lnum,
          path = location.filename,
          lnum = location.lnum,
          col = location.col,
          call = call.to,
        }
      end
      P.start("Outgoing: " .. item.name, entries, { actions = { {
        name = "呼び出し先を展開",
        key = "<C-l>",
        run = function(selected)
          calls(selected[1].call, client)
        end,
      } } })
    end, buf)
  end
  vim.lsp.buf_request_all(buf, "textDocument/prepareCallHierarchy", function(client)
    return vim.lsp.util.make_position_params(win, client.offset_encoding)
  end, function(results)
    local entries = {}
    for id, result in pairs(results) do
      for _, item in ipairs(result.result or {}) do
        entries[#entries + 1] = { text = item.name, item = item, client = vim.lsp.get_client_by_id(id) }
      end
    end
    if #entries == 1 then
      calls(entries[1].item, entries[1].client)
    else
      P.start("Call hierarchy", entries, {
        choose = function(entry)
          calls(entry.item, entry.client)
        end,
      })
    end
  end)
end

function M.setup()
  P.register("file-hide", "<leader>fff", "管理対象ファイル", M.files)
  P.register("files", "<leader>ffm", "ファイル選択", M.files)
  P.register("file-rec", "<leader>ffr", "すべてのファイル（再帰）", function()
    P.cli("All files", { "rg", "--files", "--hidden", "--no-ignore", "--glob", "!.git" })
  end)
  P.register("file-tree", "<leader>fft", "ファイル探索", function()
    extra("explorer", {}, P.options("Explorer"))
  end)
  P.register("nvim-config", "<leader><leader>c", "設定ファイル", function()
    M.files({ cwd = vim.env.XDG_CONFIG_HOME or vim.fn.stdpath("config"):match("^(.*)/[^/]+$") })
  end)
  P.register("search-files", "<leader>fr", "ファイル内容を検索", M.grep)
  P.register("search-dotfiles", "<leader><leader>r", "Dotfiles検索", function()
    M.grep({ cwd = vim.env.XDG_CONFIG_HOME or vim.fn.expand("~/.config") })
  end)
  P.register("buffer", "<leader>fb", "バッファ", buffers)
  P.register("quickfix", "<leader>fqc", "Quickfix", function()
    extra("list", { scope = "quickfix" }, P.options("Quickfix"))
  end)
  P.register("quickfix-history", "<leader>fqh", "Quickfix履歴", quickfix_history)
  P.register("help", "<leader>fh", "ヘルプ", function()
    require("mini.pick").builtin.help({}, P.options("Help"))
  end)
  for _, kind in ipairs({ "mru", "mrw", "mrr" }) do
    P.register(kind, "<leader>fm" .. kind:sub(-1), kind, function()
      history(kind)
    end)
  end
  P.register("command", "<leader>f:", "コマンド", function()
    local items = vim.fn.getcompletion("", "command")
    P.start("Commands", items, {
      choose = function(item)
        vim.api.nvim_feedkeys(":" .. item .. " ", "n", false)
      end,
    })
  end)
  P.register("command-history", "<leader>f;", "コマンド履歴", function()
    local items = {}
    for i = vim.fn.histnr(":"), 1, -1 do
      local entry = vim.fn.histget(":", i)
      if entry ~= "" then
        items[#items + 1] = entry
      end
    end
    P.start("Command history", items, {
      choose = function(item)
        vim.api.nvim_feedkeys(":" .. item, "n", false)
      end,
    })
  end)
  P.register("vim-function", "<leader>fvf", "Vim関数", function()
    P.start("Functions", vim.fn.getcompletion("", "function"), {
      choose = function(item)
        P.insert(item)
      end,
    })
  end)
  P.register("lsp-client", "<leader>flc", "LSPクライアント", lsp_clients)
  P.register("lsp-definition", "<leader>ld", "定義・型・宣言・実装", definitions)
  P.register("lsp-code-actions", "<leader>lca", "コードアクション", vim.lsp.buf.code_action, { "n", "x" })
  P.register("lsp-references", "<leader>lfr", "参照", function()
    extra("lsp", { scope = "references" }, P.options("References"))
  end)
  P.register("lsp-symbols", "<leader>lfw", "シンボル", function()
    extra("lsp", { scope = "workspace_symbol_live" }, P.options("Workspace symbols"))
  end)
  P.register("lsp-call-hierarchy", "<leader>lch", "呼び出し階層", outgoing_calls)
  P.register("pickers", "<leader><leader>f", "一覧を選択", P.menu)
end

return M
