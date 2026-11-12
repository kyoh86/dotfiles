local namespace = vim.api.nvim_create_namespace("kyoh86.mdlink")

vim.api.nvim_create_user_command("MarkdownUrlPaste", function()
  local url = vim.trim(vim.fn.getreg("*"))
  if url == "" then
    url = vim.trim(vim.fn.getreg("+"))
  end
  if url == "" then
    return
  end

  local win, buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(win)
  local mark = vim.api.nvim_buf_set_extmark(buf, namespace, cursor[1] - 1, cursor[2], { right_gravity = false })
  local function insert(title)
    if not vim.api.nvim_buf_is_loaded(buf) then
      return
    end
    local pos = vim.api.nvim_buf_get_extmark_by_id(buf, namespace, mark, {})
    if #pos == 0 then
      return
    end
    vim.api.nvim_buf_del_extmark(buf, namespace, mark)
    if not vim.bo[buf].modifiable then
      return
    end
    local text = url
    if title and title ~= "" then
      text = "[" .. title:gsub("([%[%]\\])", "\\%1") .. "](" .. url:gsub("([()\\])", "\\%1") .. ")"
    end
    local lines = vim.split(text, "\n", { plain = true })
    local row, col = pos[1], pos[2]
    local follow = vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf and vim.deep_equal(vim.api.nvim_win_get_cursor(win), { row + 1, col })
    vim.api.nvim_buf_set_text(buf, row, col, row, col, lines)
    if follow then
      vim.api.nvim_win_set_cursor(win, { row + #lines, (#lines == 1 and col or 0) + #lines[#lines] })
    end
  end

  if not url:lower():match("^https?://") then
    return insert()
  end
  local tool = require("kyoh86.lib.dotfiles_tool")("nvim-tools")
  local started = pcall(
    vim.system,
    { tool, "title", url },
    { text = true },
    vim.schedule_wrap(function(result)
      insert(result.code == 0 and vim.trim(result.stdout or "") or nil)
    end)
  )
  if not started then
    insert()
  end
end, { desc = "Paste a URL as a Markdown link" })
