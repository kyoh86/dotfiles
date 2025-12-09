local ok, ghost = pcall(require, "kyoh86.poc.codex_ghost")
if not ok then
  return
end

ghost.setup({
  -- keymaps are intentionally omitted; bind to the commands below if you want shortcuts:
  -- :CodexGhost to request, :CodexGhostAccept to insert, :CodexGhostDismiss to clear
})
