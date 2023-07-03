---@param buffer integer
---@param oupfile string a output file
---@param processor PodiumConverter
local function process(buffer, oupfile, processor)
  local podium = require("podium")
  local content = vim.api.nvim_buf_get_lines(buffer, 0, -1, true)
  local processed = podium.process(table.concat(content, "\n"), processor)
  local fp = vim.uv.fs_open(oupfile, "w", 644)
  vim.uv.fs_write(fp, processed)
  vim.uv.fs_close(fp)
  --TODO: reload buffers loading the outname
end

---@param buffer integer
local function podiumMarkdown(buffer)
  local podium = require("podium")
  local bufname = vim.api.nvim_buf_get_name(buffer)
  local outname = string.gsub(bufname, "%.pod$", ".md")
  if vim.fn.filereadable(outname) then
    vim.ui.select({ "yes", "no" }, {
      prompt = "There's already " .. outname .. "; Are you sure you overwrite it?: ",
    }, function(choice)
      if choice ~= "yes" then
        return
      end
      process(buffer, outname, podium.markdown)
    end)
  else
    process(buffer, outname, podium.markdown)
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
        vim.api.nvim_buf_create_user_command(ev.buf, "PodiumMarkdown", function()
          podiumMarkdown(ev.buf)
        end, {
          desc = "Convert the pod file to markdown",
          force = true,
        })
      end,
    })
  end,
}
return spec
