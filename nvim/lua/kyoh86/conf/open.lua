--- カーソル下のファイルを関連付けられた外部ファイルで開いたりする
local function open_cursor()
  local target = vim.fn.expand("<cfile>")
  if target == nil then
    print("No target found at cursor.")
    return
  end
  target = string.gsub(target, [[\.+$]], "")
  require("kyoh86.lib.open").gui(target)
end

vim.api.nvim_create_user_command("OpenCursor", open_cursor, {
  desc = "Open files or urls under the cursor by special handler",
})
vim.keymap.set("n", "<plug>(open-cursor-file)", open_cursor, {
  desc = "Open files or urls under the cursor by special handler",
  silent = true,
  remap = false,
  nowait = true,
})

vim.keymap.set("n", "gx", "<plug>(open-cursor-file)", { desc = "Open files or urls under the cursor by special handler" })

vim.keymap.set("n", "gf", "gF", { remap = true })
vim.keymap.set("n", "gfv", [[<cmd>vertical wincmd F<cr>]], { remap = false })
vim.keymap.set("n", "gfx", [[<cmd>horizontal wincmd F<cr>]], { remap = false })
