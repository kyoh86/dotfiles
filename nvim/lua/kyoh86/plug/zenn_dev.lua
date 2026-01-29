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
local state = {
  loaded = false,
  entered = false,
}
local tryEnable = function()
  if not state.loaded or not state.entered then
    return
  end
  vim.fn["zenn_dev#setup#commands"]({ ZennDevNewArticle = true })

  vim.keymap.set("n", "<leader>zna", "<cmd>ZennDevNewArticle<cr>", { remap = false, silent = true, desc = "zenn.dev用の記事を追加する" })
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
local leave = function()
  state.entered = false
  pcall(vim.keymap.del, "n", "<leader>zna")
  pcall(vim.keymap.del, "n", "<leader>xzz")
  pcall(vim.keymap.del, "n", "<leader>yzz")
  pcall(vim.keymap.del, "n", "<leader>xzl")
  pcall(vim.keymap.del, "n", "<leader>yzl")
  pcall(vim.api.nvim_del_user_command, "ZennDevNewArticle")
end
---@type LazySpec[]
local spec = {
  {
    "kyoh86/vim-zenn-autocmd",
    lazy = false,
    config = function()
      local au = require("kyoh86.lib.autocmd")
      vim.fn["zenn_autocmd#enable"]()
      local group = au.group("kyoh86.plug.zenn.autocmd", true)
      group:hook("User", {
        pattern = "ZennEnter",
        callback = function()
          state.entered = true
          tryEnable()
        end,
      })
      group:hook("User", { pattern = "ZennLeave", callback = leave })
    end,
  },
  {
    "kyoh86/denops-zenn_dev.vim",
    config = function()
      local au = require("kyoh86.lib.autocmd")
      au.group("kyoh86.plug.zenn_dev", true):hook("User", {
        pattern = "DenopsPluginPost:zenn_dev",
        callback = function()
          state.loaded = true
          vim.fn["zenn_dev#setup#params"]({ newArticle = { emoji = "🐼" } })
          tryEnable()
        end,
      })
    end,
    dependencies = { "denops.vim" },
  },
}
return spec
