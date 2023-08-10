if vim.opt_local.buftype:get() ~= "help" then
  --- 編集中ヘルプの見た目変更

  --- インデント設定
  local indent_size = 8
  vim.opt_local.tabstop = indent_size
  vim.opt_local.shiftwidth = indent_size
  vim.opt_local.expandtab = false

  local text_width = 78
  vim.opt_local.colorcolumn = { text_width + 2 }
  vim.opt_local.textwidth = text_width

  vim.api.nvim_set_hl(0, "helpHeader", { link = "Title" })
  vim.api.nvim_set_hl(0, "helpHeadline", { link = "Title" })
  vim.api.nvim_set_hl(0, "helpSectionDelim", { link = "Title" })
  vim.api.nvim_set_hl(0, "helpIgnore", { link = "PreProc" })
  vim.api.nvim_set_hl(0, "helpBar", { link = "PreProc" })
  vim.api.nvim_set_hl(0, "helpStar", { link = "PreProc" })
  vim.api.nvim_set_hl(0, "helpBacktick", { link = "PreProc" })
  if vim.fn.has("conceal") == 1 then
    vim.opt_local.conceallevel = 0
  end

  vim.g.autofmt_allow_over_tw = 1
  vim.opt_local.formatoptions:append({ "m", "B" })
  vim.opt_local.smartindent = true

  -- 便利機能

  ---文字列がタグかどうか確認
  ---@param word string|nil
  ---@retruns boolean
  local function is_tag(word)
    if word == nil then
      return false
    end
    if string.len(word) < 2 then
      return false
    end
    return word:sub(1, 1) == "*" and word:sub(-1) == "*"
  end

  -- Align tags
  vim.keymap.set("n", "<leader>=", function()
    local value = vim.api.nvim_get_current_line()
    local words = {}
    local tags = {}
    local terms = vim.fn.split(value, [[\s\+\zs]], true)
    for _, c in pairs(terms) do
      if is_tag(vim.fn.trim(c)) then
        table.insert(tags, vim.fn.trim(c))
      else
        table.insert(words, c)
      end
    end

    if #tags == 0 then
      vim.notify("no tags", vim.log.levels.DEBUG)
      return
    end

    local tagline = table.concat(tags, " ")
    vim.api.nvim_set_current_line(string.rep(" ", text_width - vim.fn.strdisplaywidth(tagline)) .. tagline)
    if #words > 0 then
      vim.api.nvim_put({ table.concat(words, "") }, "l", true, true)
    end
  end, { desc = "align tags" })

  -- 章区切り
  local chapter = string.rep("=", text_width)
  vim.keymap.set("n", "<leader>==", function()
    vim.api.nvim_put({ chapter }, "l", true, true)
  end, { desc = "put horizontal line" })

  -- 節区切り
  local section = string.rep("-", text_width)
  vim.keymap.set("n", "<leader>--", function()
    vim.api.nvim_put({ section }, "l", true, true)
  end, { desc = "put horizontal line" })
end
