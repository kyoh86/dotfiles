local ok, ghost = pcall(require, "kyoh86.poc.codex_ghost")
if not ok then
  return
end

ghost.setup({
  auto_trigger = false,
  debounce_ms = 200,
  context_before = 120,
  context_after = 60,
  disable_buftypes = { "help", "prompt", "quickfix", "terminal" },
})

local maps = {
  request = { "<C-x>x", "<C-x><C-x>" },
  accept = { "<C-x>a", "<C-x><C-a>" },
  dismiss = { "<C-x>d", "<C-x><C-d>" },
}

for _, lhs in ipairs(maps.request) do
  vim.keymap.set("i", lhs, function()
    ghost.request()
  end, { desc = "Codex ghost: request" })
end
for _, lhs in ipairs(maps.accept) do
  vim.keymap.set("i", lhs, function()
    ghost.accept()
  end, { desc = "Codex ghost: accept" })
end
for _, lhs in ipairs(maps.dismiss) do
  vim.keymap.set("i", lhs, function()
    ghost.dismiss()
  end, { desc = "Codex ghost: dismiss" })
end
vim.keymap.set("n", "<leader>tg", function()
  local enabled = ghost.toggle()
  vim.notify(string.format("Codex ghost %s", enabled and "enabled" or "disabled"))
end, { desc = "Codex ghost: toggle" })
