local help_dir = vim.fs.joinpath(vim.fn.stdpath("data") --[[@as string]], "lazydoc")
local help_doc_dir = vim.fs.joinpath(help_dir, "doc")

local function collect_file(plugin_name, dir, source_name, source_type)
  if source_type ~= "file" then
    return
  end
  if not string.find(source_name, "%.txt$") and string.find(source_name, "%...x$") then
    return
  end
  local dst = vim.fs.joinpath(help_doc_dir, plugin_name .. "---" .. string.gsub(source_name, "/", "---"))
  vim.fn.mkdir(vim.fs.dirname(dst), "p")
  vim.uv.fs_copyfile(vim.fs.joinpath(dir, source_name), dst)
end

local function collect()
  vim.notify("Collecting docs from lazy plugins...")
  vim.fs.rm(help_doc_dir, { recursive = true, force = true })
  vim.fn.mkdir(help_doc_dir, "p")
  local plugins = require("lazy.core.config").plugins
  for _, p in pairs(plugins) do
    local dir = vim.fs.joinpath(p.dir, "doc")
    for fname, ftype in vim.fs.dir(dir, { depth = 5 }) do
      collect_file(p.name, dir, fname, ftype)
    end
  end
  vim.cmd.helptags(help_doc_dir)
  vim.notify("Collected docs from lazy plugins")
end

return {
  help_dir = help_dir,
  collect = collect,
}
