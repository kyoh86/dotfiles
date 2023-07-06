local exts = {
  html = ".html",
  markdown = ".md",
  vimdoc = ".txt",
}

---@param buffer integer
---@param filetype "html"|"markdown"|"vimdoc"|nil
---@return "html"|"markdown"|"vimdoc",string
local function preprocess(buffer, filetype)
  if not filetype or filetype == "" then
    filetype = "vimdoc"
  end
  local bufname = vim.api.nvim_buf_get_name(buffer)
  local filename = string.gsub(bufname, "%.pod$", exts[filetype])
  return filetype, filename
end

---@param buffer integer
---@param filetype "html"|"markdown"|"vimdoc"
---@param filename string a output file
local function processToFile(buffer, filetype, filename)
  local podium = require("podium")
  local processor = podium.PodiumProcessor.new(podium[filetype])
  local content = vim.api.nvim_buf_get_lines(buffer, 0, -1, true)
  local processed = processor:process(table.concat(content, "\n"))
  local mode = 420 -- 0644(8) == 420(10)
  local fp = vim.uv.fs_open(filename, "w", mode)
  vim.uv.fs_write(fp, processed)
  vim.uv.fs_close(fp)
  --TODO: reload buffers loading the outname
end

---Make preview window for the podium
---@param buffer integer
---@param filetype "html"|"markdown"|"vimdoc"
---@param filename string
---@param preview boolean
local function processToBuffer(buffer, filetype, filename, preview)
  local podium = require("podium")
  local content = table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, true), "\n")
  local processor = podium.PodiumProcessor.new(podium[filetype])
  local output = processor:process(content)
  vim.cmd.new(filename)
  vim.api.nvim_buf_set_lines(0, 0, -1, true, vim.split(output, "\n"))
  if preview then
    vim.bo[0].modified = false
    vim.bo[0].readonly = true
  end
end

---@type LazySpec
local spec = {
  "tani/podium",
  config = function()
    local group = vim.api.nvim_create_augroup("kyoh86-plug-podium-commands", { clear = true })
    vim.api.nvim_create_autocmd({ "FileType" }, {
      group = group,
      pattern = "pod",
      callback = function(ev)
        vim.api.nvim_buf_create_user_command(ev.buf, "PodiumWrite", function(opts)
          local filetype, filename = preprocess(ev.buf, opts.args)
          if vim.fn.filereadable(filename) ~= 0 then
            vim.ui.select({ "yes", "no" }, {
              prompt = "There's already " .. filename .. "; Are you sure you overwrite it?: ",
            }, function(choice)
              if choice ~= "yes" then
                return
              end
              processToFile(ev.buf, filetype, filename)
            end)
          else
            processToFile(ev.buf, filetype, filename)
          end
        end, {
          desc = "Convert pod with podium and write it to file",
          nargs = "?",
          force = true,
        })
        vim.api.nvim_buf_create_user_command(ev.buf, "Podium", function(opts)
          local filetype, filename = preprocess(ev.buf, opts.args)
          processToBuffer(ev.buf, filetype, filename, false)
        end, {
          desc = "Convert pod with podium",
          nargs = "?",
          force = true,
        })
        vim.api.nvim_buf_create_user_command(ev.buf, "PodiumPreview", function(opts)
          local filetype, filename = preprocess(ev.buf, opts.args)
          processToBuffer(ev.buf, filetype, filename, false)
        end, {
          desc = "Convert pod with podium and write it to file",
          nargs = "?",
          force = true,
        })
      end,
    })
  end,
}
return spec
