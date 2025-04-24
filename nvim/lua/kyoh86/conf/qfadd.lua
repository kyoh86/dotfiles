vim.o.chistory = 100

local function get_focused_qfitem(line1, line2)
  return { vim.tbl_map(function(item)
    return vim.tbl_extend("force", item, { nr = "$" })
  end, unpack(vim.fn.getqflist(), line1, line2)) }
end

local function get_focused_lineitem(line1, line2)
  local filename = vim.fn.expand("%:p")
  local list = {}
  for lnum = line1, line2 do
    local text = vim.fn.getline(lnum)
    if vim.fn.trim(text) ~= "" then
      table.insert(list, { filename = filename, lnum = lnum, text = text })
    end
  end
  return list
end

-- Get the focused location items
local function get_focused_location(line1, line2)
  if vim.bo.buftype == "quickfix" then
    return get_focused_qfitem()
  elseif vim.bo.buftype == "" then
    return get_focused_lineitem(line1, line2)
  end
end

vim.api.nvim_create_user_command("QfAdd", function(opts)
  local list = get_focused_location(opts["line1"], opts["line2"])
  local hidden = false
  local action = "a"
  ---@type string|integer|nil
  local nr = "$"
  for _, arg in pairs(opts.fargs) do
    if arg == "-hidden" or arg == "-h" then
      hidden = true
    elseif arg == "-reset" or arg == "-r" then
      if action ~= " " then
        action = "r"
      end
    elseif arg == "-new" or arg == "-n" then
      action = " "
      nr = nil
    elseif string.match(arg, "^-?%d+$") then
      local num = tonumber(arg) --[[@as integer]]
      if num > 0 then
        action = "a"
        nr = num
      end
    end
  end
  vim.fn.setqflist({}, action, {
    nr = nr --[[@as integer]],
    items = list,
  })
  if not hidden then
    vim.cmd.copen()
  end
end, { force = true, range = true, nargs = "*" })
vim.keymap.set({ "!a" }, "Qfadd", "<cmd>QfAdd<cr>", { remap = false, desc = "Quickfixにカーソル位置を追加する" })
vim.keymap.set({ "n", "v" }, "<leader>qa", "<cmd>QfAdd<cr>", { remap = false, desc = "Quickfixにカーソル位置を追加する" })
