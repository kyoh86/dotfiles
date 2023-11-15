local conf = {
  data_dir = vim.fn.stdpath("data") .. "/todo",
}

local def = {
  list_name = "list.json",
}

local M = {}

function M.setup(user_config)
  if user_config then
    conf = vim.tbl_deep_extend("force", conf, user_config)
  end
end

--- データファイルのパスを生成する関数
local function data_path(filename)
  return conf.data_dir .. "/" .. filename
end

--- エラーログを出力する
--- ログは `error.log` に追記される
--- また、vim-notifyを使ってエラーを通知する
--- @param message string
local function log_error(message)
  local log_file = data_path("error.log")
  local file = io.open(log_file, "a")
  if file then
    file:write(os.date("%Y-%m-%d %H:%M:%S") .. ": " .. message .. "\n")
    file:close()
  end
  vim.notify(message, vim.log.levels.ERROR)
end

local function generate_uuid()
  local random = math.random
  local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
  return string.gsub(template, "[xy]", function(c)
    local v = (c == "x") and random(0, 0xf) or random(8, 0xb)
    return string.format("%x", v)
  end)
end

--- タスクリストを読み込む
--- @return table, string|nil
function M.load_task_list()
  local list_path = data_path(def.list_name)
  local file = io.open(list_path, "r")

  if not file then
    -- ファイルが存在しない場合は空のリストを返す
    return {}, "Todo list file not found."
  end

  local content = file:read("*a")
  file:close()

  local status, task_list = pcall(vim.fn.json_decode, content)
  if not status then
    -- JSONの解析に失敗した場合はエラーメッセージを返す
    return {}, "Failed to decode the todo list."
  end

  return task_list, nil -- 成功した場合はタスクリストとnil（エラーなし）を返す
end

--- タスクリストを保存する
--- @param task_list table
function M.save_task_list(task_list)
  local list_path = data_path(def.list_name)
  local file = io.open(list_path, "w")

  if not file then
    log_error("Could not open the todo list file to save.")
    return
  end

  file:write(vim.fn.json_encode(task_list))
  file:close()
end

function M.add_todo()
  local uuid = generate_uuid()
  local filepath = data_path(uuid .. ".md")

  vim.fn.mkdir(conf.data_dir, "p")
  vim.cmd("edit " .. filepath)

  -- 新しいバッファにUUIDを設定
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_var(bufnr, "todo_uuid", uuid)

  -- 新しいタスクを `list.json` に追加
  M.update_list(uuid, { title = "", issue_number = nil, api_issue_url = nil })

  -- ここで自動同期の設定も行う
  M.setup_autosync(bufnr)
end

function M.update_list(task_uuid, task_data)
  local list, err = M.load_task_list()
  if err then
    vim.notify(err, vim.log.levels.INFO)
  end

  -- 既存のタスクデータを取得または新規作成
  local existing_task_data = list[task_uuid] or { comments = {} }

  -- タスクデータ（タイトル、Issue URLなど）の更新
  existing_task_data.title = task_data.title
  existing_task_data.api_issue_url = task_data.api_issue_url
  existing_task_data.issue_number = task_data.issue_number

  -- コメントリストの更新
  for _, comment in ipairs(task_data.comments or {}) do
    table.insert(existing_task_data.comments, comment)
  end

  -- 更新されたタスクデータをlistに反映
  list[task_uuid] = existing_task_data

  -- list.jsonファイルの更新
  M.save_task_list(list)
end

--- コマンドを実行し、その結果を返す
--- @param cmd string
--- @return string
local function execute_command(cmd)
  local handle = io.popen(cmd, "r")
  if not handle then
    log_error("Failed to execute command: " .. cmd)
    return ""
  end
  local result = handle:read("*a")
  handle:close()
  return result
end

--- タスクバッファの内容を解析する
--- タスクバッファは以下の形式であることを前提とする
---
--- <タイトル>
--- <本文>
--- <==={UUID}===>
--- <コメント1>
--- <==={UUID}===>
--- <コメント2>
--- ...
---
--- @param bufnr number
--- @return table
function M.parse_buffer(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local title = lines[1]
  local body = {}
  local comments = {}
  local current_comment = nil

  for i = 2, #lines do
    local line = lines[i]
    if line:match("^<==={.+}===>$") then
      -- 新しいコメントの開始
      if current_comment then
        table.insert(comments, current_comment)
      end
      current_comment = { uuid = line:match("^<==={(.+)}===>$"), body = {} }
    else
      if current_comment then
        table.insert(current_comment.body, line)
      else
        table.insert(body, line)
      end
    end
  end
  if current_comment then
    table.insert(comments, current_comment)
  end

  return {
    title = title,
    body = table.concat(body, "\n"),
    comments = comments,
  }
end

--- タスクバッファの内容をGitHub Issueに反映する
--- @param create boolean
--- @param task_bufnr number
function M.reflect_issue(create, task_bufnr)
  -- バッファからタスクの内容を解析
  local parsed_data = M.parse_buffer(task_bufnr)
  local title = parsed_data.title
  local body = parsed_data.body
  local comments = parsed_data.comments

  -- list.jsonを読み込む
  local uuid = vim.api.nvim_buf_get_var(task_bufnr, "todo_uuid")
  local list = M.load_task_list()
  local task_data = list[uuid] or { comments = {} }

  -- Issueを更新、または新しいIssueを作成
  if task_data.api_issue_url then
    if not M.update_issue(task_data.api_issue_url, title, body) then
      log_error("Failed to update issue.")
      return
    end
  elseif create then
    local new_issue_url = M.create_issue(title, body)
    if not new_issue_url then
      log_error("Failed to create new issue.")
      return
    end
    task_data.api_issue_url = new_issue_url
  else
    return
  end

  -- 各コメントを処理
  for _, comment in ipairs(comments) do
    local comment_data = task_data.comments[comment.uuid] or {}
    if comment_data.issue_comment_url then
      -- 既存のコメントを更新
      if not M.update_issue_comment(comment_data.issue_comment_url, table.concat(comment.body, "\n")) then
        log_error("Failed to update comment: " .. comment.uuid)
      end
    else
      -- 新しいコメントを作成
      local new_comment_url = M.create_issue_comment(task_data.api_issue_url, table.concat(comment.body, "\n"))
      if new_comment_url then
        comment_data.issue_comment_url = new_comment_url
      else
        log_error("Failed to create new comment: " .. comment.uuid)
      end
    end
    task_data.comments[comment.uuid] = comment_data
  end

  -- list.jsonを更新
  M.update_list(uuid, task_data)
end

function M.create_issue(title, body)
  -- GitHub Issueを作成するコマンドを構築
  local create_cmd = string.format('gh api -X POST /issues --field title=%s --field body=%s --jq ".url"', vim.fn.shellescape(title), vim.fn.shellescape(body))

  -- コマンドの実行と結果の処理
  local api_issue_url = execute_command(create_cmd)

  if api_issue_url == "" then
    log_error("Failed to create GitHub Issue.")
    return nil
  else
    log_error("GitHub Issue created successfully.")
    return api_issue_url:match('"(.-)"') -- JSON文字列からURLを抽出
  end
end

function M.update_issue(api_issue_url, title, body)
  -- IssueのAPI URLを確認
  if not api_issue_url or api_issue_url == "" then
    log_error("Error: Invalid GitHub Issue API URL")
    return false
  end

  -- GitHub Issueを更新するコマンドを構築
  local update_cmd = string.format("gh api -X PATCH %s --field title=%s --field body=%s", api_issue_url, vim.fn.shellescape(title), vim.fn.shellescape(body))

  -- コマンドの実行と結果の処理
  local result = execute_command(update_cmd)

  if result:match("Error:") then
    log_error("Failed to update GitHub Issue: " .. result)
    return false
  else
    vim.notify("GitHub Issue updated successfully.", vim.log.levels.INFO)
    return true
  end
end

function M.create_issue_comment(api_issue_url, comment_body)
  -- GitHubコメントを作成するコマンドを構築
  local create_cmd = string.format('gh api -X POST %s/comments --field body=%s --jq ".url"', api_issue_url, vim.fn.shellescape(comment_body))

  -- コマンドの実行と結果の処理
  local api_comment_url = execute_command(create_cmd)

  if api_comment_url == "" then
    log_error("Failed to create GitHub Comment.")
    return nil
  else
    vim.notify("GitHub Comment created successfully.", vim.log.levels.INFO)
    return api_comment_url:match('"(.-)"') -- JSON文字列からURLを抽出
  end
end

function M.update_issue_comment(api_comment_url, new_body)
  -- コメントのAPI URLを確認
  if not api_comment_url or api_comment_url == "" then
    log_error("Error: Invalid GitHub Comment API URL")
    return false
  end

  -- GitHubコメントを更新するコマンドを構築
  local update_cmd = string.format("gh api -X PATCH %s --field body=%s", api_comment_url, vim.fn.shellescape(new_body))

  -- コマンドの実行と結果の処理
  local result = execute_command(update_cmd)

  if result:match("Error:") then
    log_error("Failed to update GitHub Comment: " .. result)
    return false
  else
    vim.notify("GitHub Comment updated successfully.", vim.log.levels.INFO)
    return true
  end
end

function M.setup_autosync(task_bufnr)
  -- 保存時に実行される自動コマンドを設定
  vim.api.nvim_create_autocmd("BufWritePost", {
    buffer = task_bufnr,
    callback = function()
      M.reflect_issue(false, task_bufnr)
    end,
  })
end

function M.add_comment()
  -- 現在のタスクバッファの識別子を取得
  local task_bufnr = vim.api.nvim_get_current_buf()
  local task_uuid = vim.api.nvim_buf_get_var(task_bufnr, "todo_uuid")
  if not task_uuid then
    vim.api.nvim_err_writeln("No task file is currently open.")
    return
  end

  -- コメント入力用の新しいバッファを作成
  vim.cmd("new")
  vim.bo.buftype = "acwrite"
  vim.bo.filetype = "markdown"

  -- バッファを保存した際の処理を設定
  vim.cmd('autocmd BufWriteCmd <buffer> lua require"todo".save_comment(' .. task_bufnr .. ")")
end

function M.save_comment(task_bufnr, task_uuid)
  local comment_uuid = generate_uuid() -- generate_uuidはUUIDを生成する関数
  local comment = table.concat(vim.fn.getline(1, "$"), "\n")
  if comment == "" then
    vim.api.nvim_err_writeln("No comment was entered.")
    return
  end

  -- 元のタスクバッファにコメントを追加
  local separator = "<==={" .. comment_uuid .. "}===>\n"
  local comment_text = separator .. comment
  vim.api.nvim_buf_set_lines(task_bufnr, -1, -1, false, { comment_text })

  -- list.jsonにコメント情報を追加
  M.update_comment_list(task_uuid, comment_uuid)

  -- コメント入力バッファを閉じる
  vim.cmd("bd!")
end

function M.update_comment_list(task_uuid, comment_uuid)
  local list = M.load_task_list()
  local task_data = list[task_uuid] or { comments = {} }

  table.insert(task_data.comments, { uuid = comment_uuid, issue_comment_url = nil })
  list[task_uuid] = task_data

  M.save_task_list(list)
end

vim.cmd([[
function! TodoCommandCompletion(...)
  return [ 'new', 'note', 'sync' ]
endfunction
command! -nargs=? -complete=customlist,TodoCommandCompletion Todo call v:lua.handle_todo_command(<f-args>)
]])

function handle_todo_command(args)
  -- サブコマンドに基づいて適切なアクションを実行
  if args == "new" then
    -- 新しいタスクを作成
    M.add_todo()
  elseif args == "note" then
    -- コメントを追加
    M.add_comment()
  elseif args == "sync" then
    -- タスクを同期
    M.reflect_issue(true, vim.api.nvim_get_current_buf())
  elseif args == "search" then
    --- TODOコメントを探し出す
    vim.cmd([[silent! grep! -i 'TODO\|UNDONE\|HACK\|FIXME' | copen]])
  else
    print("Invalid Todo subcommand")
  end
end

-- To use commands like lower-letter
require("kyoh86.conf.cmd_alias").set("todo", "Todo")

return M
