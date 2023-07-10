local group = vim.api.nvim_create_augroup("kyoh86-conf-tomlvsinp", { clear = true })
local vsnip_dir = vim.fn.resolve(vim.fn.stdpath("config") .. "/vsnip")

vim.api.nvim_create_autocmd("BufWritePost", {
  group = group,
  pattern = "*.toml",
  callback = function(ev)
    local path = vim.fn.resolve(vim.fn.fnamemodify(ev.file, ":p"))
    if vim.fn.fnamemodify(path, ":h") ~= vsnip_dir then
      return
    end
    kyoh86.fa.denops.request("tomlvsnip", "process", {
      path,
      table.concat(vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false), "\n"),
      4,
    })
  end,
})
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = group,
  pattern = "*.json",
  callback = function(ev)
    local path = vim.fn.resolve(vim.fn.fnamemodify(ev.file, ":p"))
    if vim.fn.fnamemodify(path, ":h") ~= vsnip_dir then
      return
    end
    vim.api.nvim_buf_create_user_command(ev.buf, "ReverseToTOML", function()
      kyoh86.fa.denops.request("tomlvsnip", "reverse", {
        path,
        table.concat(vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false), "\n"),
        4,
      })
    end, {})
  end,
})
