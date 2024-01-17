--- integrations for zenn.dev
---@param prefix? string  A URL prefix for my zenn.dev posts
local zenn_url = function(prefix)
  prefix = prefix or "https://zenn.dev/kyoh86/"
  local name = vim.api.nvim_buf_get_name(0)
  local relname = vim.fn.fnamemodify(name, ":.")
  local dirname = vim.fn.fnamemodify(relname, ":h")
  local extname = vim.fn.fnamemodify(relname, ":e")

  if dirname == "articles" and extname == "md" then
    return prefix .. "articles/" .. vim.fn.fnamemodify(relname, ":t:s?\\.md$??")
  else
    vim.notify(string.format("opening the %q is not supported", dirname), vim.log.levels.ERROR)
  end
  return nil
end
local zenn_keymap = function()
  vim.keymap.set("n", "<leader>zna", "<cmd>ZennNewArticle<cr>", { remap = false, silent = true, desc = "zenn.dev用の記事を追加する" })
  vim.keymap.set("n", "<leader>xzz", function()
    local url = zenn_url()
    if url ~= nil then
      require("kyoh86.lib.open").gui(url)
    end
  end, { remap = false, silent = true, desc = "現在のバッファの記事をZenn.devで開く" })
  vim.keymap.set("n", "<leader>yzz", function()
    local url = zenn_url()
    if url ~= nil then
      vim.fn.setreg("+", url)
    end
  end, { remap = false, silent = true, desc = "現在のバッファの記事のZenn.devのURLをYankする" })
  vim.keymap.set("n", "<leader>xzl", function()
    local url = zenn_url("http://localhost:8000/")
    if url ~= nil then
      require("kyoh86.lib.open").gui(url)
    end
  end, { remap = false, silent = true, desc = "現在のバッファの記事をローカルプレビューで開く" })
  vim.keymap.set("n", "<leader>yzl", function()
    local url = zenn_url("http://localhost:8000/")
    if url ~= nil then
      vim.fn.setreg("+", url)
    end
  end, { remap = false, silent = true, desc = "現在のバッファの記事のローカルプレビューのURLをYankする" })
end
local zenn_keymap_reset = function()
  pcall(vim.keymap.del, "n", "<leader>zna")
  pcall(vim.keymap.del, "n", "<leader>xzz")
  pcall(vim.keymap.del, "n", "<leader>yzz")
  pcall(vim.keymap.del, "n", "<leader>xzl")
  pcall(vim.keymap.del, "n", "<leader>yzl")
end
---@type LazySpec[]
local spec = {
  {
    "kyoh86/vim-zenn-autocmd",
    lazy = false,
    config = function()
      vim.fn["zenn_autocmd#enable"]()
      local group = vim.api.nvim_create_augroup("kyoh86-plug-zenn-autocmd", { clear = true })
      vim.api.nvim_create_autocmd("User", { pattern = "ZennEnter", group = group, callback = zenn_keymap })
      vim.api.nvim_create_autocmd("User", { pattern = "ZennLeave", group = group, callback = zenn_keymap_reset })
    end,
  },
  {
    "kkiyama117/zenn-vim",
    dependencies = { "vim-zenn-autocmd" },
    event = { "User ZennEnter" },
    config = function()
      vim.g["zenn#article#edit_new_cmd"] = "edit"
      vim.api.nvim_create_user_command("ZennUpdate", function()
        vim.fn["zenn#update"]()
      end, { nargs = 0 })
      vim.api.nvim_create_user_command("ZennPreview", function(cmd)
        vim.fn["zenn#preview"](cmd.args)
      end, { nargs = "*" })
      vim.api.nvim_create_user_command("ZennStopPreview", function()
        vim.fn["zenn#stop_preview"]()
      end, { nargs = 0 })
      vim.api.nvim_create_user_command("ZennNewArticle", function(cmd)
        vim.fn["zenn#new_article"](cmd.args)
      end, { nargs = "*" })
      vim.api.nvim_create_user_command("ZennNewBook", function(cmd)
        vim.fn["zenn#new_book"](cmd.args)
      end, { nargs = "*" })
    end,
  },
}
return spec
