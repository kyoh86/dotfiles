local group = vim.api.nvim_create_augroup("kyoh86-plug-rest", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  pattern = "http",
  group = group,
  callback = function()
    vim.keymap.set("n", "<leader>x", "<plug>RestNvim", { buffer = true, silent = true, desc = "Execute REST request" })
    vim.keymap.set("n", "<leader>rp", "<plug>RestNvimPreview", { buffer = true, silent = true, desc = "Preview REST request" })
    vim.keymap.set("n", "<leader>rl", "<plug>RestNvimLast", { buffer = true, silent = true, desc = "Show the last REST response" })
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
