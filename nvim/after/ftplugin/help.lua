if vim.opt_local.buftype:get() == "help" then
  --- 参照中ヘルプの利便性向上

  --- Neovim本体のヘルプドキュメントを開いてるか判定する
  local function is_runtime_doc()
    local filepath = vim.fn.expand("%:p")
    local vimruntime = vim.env.VIMRUNTIME
    return vimruntime and filepath:find(vim.fs.joinpath(vimruntime, "doc")) ~= nil
  end

  --- 指定行からタグを抽出する
  local function get_tag_from_line(line)
    return line:match("%*([^%*]+)%*")
  end

  --- 直近のタグを検索
  local function find_closest_tag()
    -- 現在行でタグを抽出
    local current_line = vim.api.nvim_get_current_line()
    local tag = get_tag_from_line(current_line)

    -- 現在行にタグがなければ直前のタグを検索
    if not tag then
      local tag_pos = vim.fn.search("\\*.*\\*", "bn")
      if tag_pos > 0 then
        local tag_line = vim.fn.getline(tag_pos)
        tag = get_tag_from_line(tag_line)
      end
    end

    return tag
  end

  --- Neovim docsのURLを生成
  local function generate_neovim_doc_url()
    local base_url = "https://neovim.io/doc/user/"
    local helpfile = vim.fn.expand("%:t:r")
    local tag = find_closest_tag()
    if tag then
      return string.format("%s%s.html#%s", base_url, helpfile, tag)
    else
      return string.format("%s%s.html", base_url, helpfile)
    end
  end

  --- Neovim docsを開く
  local function open_neovim_doc()
    -- Neovim本体のヘルプドキュメントでない場合はスキップ
    if not is_runtime_doc() then
      print("This is not a runtime doc file. Skipping.")
      return
    end

    local doc_url = generate_neovim_doc_url()
    vim.ui.open(doc_url)
  end

  vim.keymap.set("n", "<leader>w", open_neovim_doc, { buffer = true })
else
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
  vim.keymap.set("n", "<leader>>", function()
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

    local nextline = vim.fn.trim(table.concat(words, ""), " \t", 2)
    if nextline and string.len(nextline) > 0 then
      vim.api.nvim_put({ nextline }, "l", true, true)
    end
  end, { desc = "タグを右寄せにする" })

  -- 章区切り
  local chapter = string.rep("=", text_width)
  vim.keymap.set("n", "<leader>==", function()
    vim.api.nvim_put({ chapter }, "l", true, true)
  end, { desc = "水平線===を入れる" })

  -- 節区切り
  local section = string.rep("-", text_width)
  vim.keymap.set("n", "<leader>--", function()
    vim.api.nvim_put({ section }, "l", true, true)
  end, { desc = "水平線---を入れる" })
end
