local function is_tags_file(source_name, source_type)
  if source_type ~= "file" then
    return false
  end
  if source_name == "tags" then
    return true
  end
  if string.find(source_name, "^tags-.+$") then
    return true
  end
  return false
end

local after_docs_dir = vim.fs.joinpath(vim.fn.stdpath("config") --[[@as string]], "after", "doc")

local function collect()
  vim.notify("Collecting help tags from lazy plugins...")

  vim.fn.mkdir(after_docs_dir, "p")

  local buffers = {}

  local plugins = require("lazy.core.config").plugins
  for _, p in pairs(plugins) do
    local dir = vim.fs.joinpath(p.dir, "doc")
    for fname in vim.iter(vim.fs.dir(dir)):filter(is_tags_file) do
      local buf = vim.tbl_get(buffers, fname)
      if buf == nil then
        buf = vim.api.nvim_create_buf(false, true)
        buffers[fname] = buf
      end
      for _, line in pairs(vim.fn.readfile(vim.fs.joinpath(dir, fname))) do
        local words = vim.split(line, "\t")
        words[2] = vim.fs.joinpath(dir, words[2])
        vim.api.nvim_buf_set_lines(buf, 0, 0, true, { vim.fn.join(words, "\t") })
      end
    end
  end

  for name, buf in pairs(buffers) do
    vim.api.nvim_buf_call(buf, function()
      vim.cmd.sort("u")
      vim.cmd.write({ args = { vim.fs.joinpath(after_docs_dir, name) }, bang = true })
    end)
  end
  vim.notify("Collected docs from lazy plugins")
end

return {
  collect = collect,
}
