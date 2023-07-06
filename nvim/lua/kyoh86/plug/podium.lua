---@param buffer integer
---@param outfile string a output file
---@param filetype "html"|"markdown"|"vimdoc"
local function processToFile(buffer, outfile, filetype)
  local podium = require("podium")
  local processor = podium.PodiumProcessor.new(podium[filetype])
  local content = vim.api.nvim_buf_get_lines(buffer, 0, -1, true)
  local processed = processor:process(table.concat(content, "\n"))
  local mode = 420 -- 0644(8) == 420(10)
  local fp = vim.uv.fs_open(outfile, "w", mode)
  vim.uv.fs_write(fp, processed)
  vim.uv.fs_close(fp)
  --TODO: reload buffers loading the outname
end

---@param filetype "html"|"markdown"|"vimdoc"|nil
---@return "html"|"markdown"|"vimdoc"
local function defaultFiletype(filetype)
  if not filetype or filetype == "" then
    return "vimdoc"
  end
  return filetype
end

local exts = {
  html = ".html",
  markdown = ".md",
  vimdoc = ".txt",
}

---@param podname string
---@param filetype "html"|"markdown"|"vimdoc"
---@return string
local function convertFilename(podname, filetype)
  local outname = string.gsub(podname, "%.pod$", exts[filetype])
  return outname
end

---Make preview window for the podium
---@param buffer integer
---@param filetype "html"|"markdown"|"vimdoc"|nil
---@param preview boolean
local function processToBuffer(buffer, filetype, preview)
  local podium = require("podium")
  local ft = defaultFiletype(filetype)
  local input = table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, true), "\n")
  local processor = podium.PodiumProcessor.new(podium[ft])
  local output = processor:process(input)
  local bufname = vim.api.nvim_buf_get_name(buffer)
  local outname = convertFilename(bufname, ft)
  vim.cmd.new(outname)
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
          local ft = defaultFiletype(opts.args)
          local bufname = vim.api.nvim_buf_get_name(ev.buf)
          local outname = convertFilename(bufname, ft)
          if vim.fn.filereadable(outname) ~= 0 then
            vim.ui.select({ "yes", "no" }, {
              prompt = "There's already " .. outname .. "; Are you sure you overwrite it?: ",
            }, function(choice)
              if choice ~= "yes" then
                return
              end
              processToFile(ev.buf, outname, ft)
            end)
          else
            processToFile(ev.buf, outname, ft)
          end
        end, {
          desc = "Convert pod with podium and write it to file",
          nargs = "?",
          force = true,
        })
        vim.api.nvim_buf_create_user_command(ev.buf, "Podium", function(opts)
          processToBuffer(ev.buf, opts.args, false)
        end, {
          desc = "Convert pod with podium",
          nargs = "?",
          force = true,
        })
        vim.api.nvim_buf_create_user_command(ev.buf, "PodiumPreview", function(opts)
          processToBuffer(ev.buf, opts.args, true)
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
