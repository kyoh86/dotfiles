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
  vim.keymap.set("n", "<leader>zna", "<cmd>ZennNewArticle<cr>", { remap = false, silent = true, desc = "create new aricle for the zenn.dev" })
  vim.keymap.set("n", "<leader>zuzo", function()
    local url = zenn_url()
    if url ~= nil then
      require("kyoh86.lib.open").gui(url)
    end
  end, { remap = false, silent = true, desc = "open current aricle on the zenn.dev" })
  vim.keymap.set("n", "<leader>zuzc", function()
    local url = zenn_url()
    if url ~= nil then
      vim.fn.setreg("+", url)
    end
  end, { remap = false, silent = true, desc = "open current aricle on the zenn.dev" })
  vim.keymap.set("n", "<leader>zulo", function()
    local url = zenn_url("http://localhost:8000/")
    if url ~= nil then
      require("kyoh86.lib.open").gui(url)
    end
  end, { remap = false, silent = true, desc = "open current aricle on the zenn.dev" })
  vim.keymap.set("n", "<leader>zulc", function()
    local url = zenn_url("http://localhost:8000/")
    if url ~= nil then
      vim.fn.setreg("+", url)
    end
  end, { remap = false, silent = true, desc = "open current aricle on the zenn.dev" })
end
local zenn_keymap_reset = function()
  pcall(vim.keymap.del, "n", "<leader>zna")
  pcall(vim.keymap.del, "n", "<leader>zfa")
  pcall(vim.keymap.del, "n", "<leader>fza")
end
---@type LazySpec[]
local spec = {
  {
    "kyoh86/vim-zenn-autocmd",
    lazy = false,
    config = function()
      kyoh86.fa.zenn_autocmd.enable()
      local group = vim.api.nvim_create_augroup("kyoh86-plug-zenn-autocmd", { clear = true })
      vim.api.nvim_create_autocmd("User", { pattern = "ZennEnter", group = group, callback = zenn_keymap })
      vim.api.nvim_create_autocmd("User", { pattern = "ZennLeave", group = group, callback = zenn_keymap_reset })
    end,
  },
  {
    "kkiyama117/zenn-vim",
    dependencies = { "kyoh86/vim-zenn-autocmd" },
    event = { "User ZennEnter" },
    config = function()
      vim.g["zenn#article#edit_new_cmd"] = "edit"
      vim.cmd([[
        command! -nargs=0 ZennUpdate call zenn#update()
        command! -nargs=* ZennPreview call zenn#preview(<f-args>)
        command! -nargs=0 ZennStopPreview call zenn#stop_preview()
        command! -nargs=* ZennNewArticle call zenn#new_article(<f-args>)
        command! -nargs=* ZennNewBook call zenn#new_book(<f-args>)
      ]])
    end,
  },
}
return spec
