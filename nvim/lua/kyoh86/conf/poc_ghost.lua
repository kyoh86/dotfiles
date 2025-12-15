local ok, ghost = pcall(require, "kyoh86.poc.ghost")
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
