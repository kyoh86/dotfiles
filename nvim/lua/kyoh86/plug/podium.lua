local DefaultFilePermissions = 420 -- 0644(8) == 420(10)
local DefaultDirectoryPermissions = 493 -- 0755(8) == 493(10)

---@param buffer integer
---@param filetype "markdown"|"vimdoc"
---@param filename string a output file
local function processToFile(buffer, filetype, filename)
  local podium = require("podium")
  local processor = podium[filetype]
  local content = vim.api.nvim_buf_get_lines(buffer, 0, -1, true)
  local processed = podium.process(processor, table.concat(content, "\n"))
  local mode = DefaultFilePermissions
  local fp = vim.uv.fs_open(filename, "w", mode)
  vim.uv.fs_write(fp, processed)
  vim.uv.fs_close(fp)
end

---@param bang boolean
---@param buffer integer
---@param filename string
local function convertReadmePod(bang, buffer, filename)
  local processors = {}
  local bufname = vim.fn.bufname(buffer)
  if bufname == "README.pod" or bufname == "readme.pod" then
    vim.notify("Processing README document to markdown and vimdoc", vim.log.levels.info)
    table.insert(processors, {
      filename = "README.md",
      filetype = "markdown",
    })
    vim.uv.fs_mkdir("doc", DefaultDirectoryPermissions)
    table.insert(processors, {
      filename = "doc/" .. vim.fs.basename(vim.fn.getcwd()) .. ".txt",
      filetype = "vimdoc",
    })
  else
    vim.notify("Processing individual document to vimdoc", vim.log.levels.info)
    table.insert(processors, {
      filename = string.gsub(filename, "%.pod$", ".txt"),
      filetype = "vimdoc",
    })
  end
  for _, p in pairs(processors) do
    if bang or vim.fn.filereadable(p.filename) == 0 then
      processToFile(buffer, p.filetype, p.filename)
    else
      vim.ui.select({ "yes", "no" }, {
        prompt = "There's already " .. p.filename .. "; Are you sure you overwrite it?: ",
      }, function(choice)
        if choice ~= "yes" then
          return
        end
        processToFile(buffer, p.filetype, p.filename)
      end)
    end
  end
end

---@type LazySpec
local spec = {
  "tani/podium",
  config = function()
    local group = vim.api.nvim_create_augroup("kyoh86-plug-podium-commands", { clear = true })

    vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
      group = group,
      pattern = { "*.pod" },
      callback = function(ev)
        vim.api.nvim_buf_create_user_command(ev.buf, "Podium", function(opts)
          convertReadmePod(opts.bang, ev.buf, ev.file)
        end, {
          desc = "Convert readme.pod with podium and write it to file",
          force = true,
          bang = true,
        })
      end,
    })
  end,
}
return spec
