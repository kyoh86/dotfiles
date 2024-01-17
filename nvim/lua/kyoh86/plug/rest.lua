local group = vim.api.nvim_create_augroup("kyoh86-plug-rest", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  pattern = "http",
  group = group,
  callback = function()
    vim.keymap.set("n", "<leader>xx", "<plug>RestNvim", { buffer = true, silent = true, desc = "RESTリクエストを実行する" })
    vim.keymap.set("n", "<leader>xr", "<plug>RestNvimPreview", { buffer = true, silent = true, desc = "RESTリクエストをプレビューする" })
    vim.keymap.set("n", "<leader>ir", "<plug>RestNvimLast", { buffer = true, silent = true, desc = "最後のRESTレスポンスを表示する" })
  end,
})

---@type LazySpec
local spec = {
  "rest-nvim/rest.nvim",
  dependencies = { "plenary.nvim" },
  ft = "rest",
  opts = {
    -- Open request results in a horizontal split
    result_split_horizontal = false,
    -- Skip SSL verification, useful for unknown certificates
    skip_ssl_verification = false,
    -- Highlight request on run
    highlight = {
      enabled = true,
      timeout = 150,
    },
    result = {
      -- toggle showing URL, HTTP info, headers at top the of result window
      show_url = true,
      show_http_info = true,
      show_headers = true,
    },
    -- Jump to request line on run
    jump_to_request = false,
    env_file = ".env",
    custom_dynamic_variables = {},
    yank_dry_run = true,
  },
}
return spec
