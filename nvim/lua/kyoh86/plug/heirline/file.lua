--- File情報
local utils = require("heirline.utils")

local FileInfo = {
  condition = function()
    -- バッファがファイルを開いているかどうか
    local filename = vim.api.nvim_buf_get_name(0)
    return vim.fn.empty(vim.fn.fnamemodify(filename, "%:t")) == 0 or vim.bo.buftype == "quickfix"
  end,

  init = function(self)
    if vim.opt_local.buftype == "terminal" then
      self.filename = "%{b:term_title}"
    end
    self.filename = vim.api.nvim_buf_get_name(0)
  end,
}

local FileIcon = {
  init = function(self)
    local filename = self.filename
    local extension = vim.fn.fnamemodify(filename, ":e")
    self.icon, _ = require("nvim-web-devicons").get_icon_color(filename, extension, { default = true })
  end,
  provider = function(self)
    return " " .. (self.icon and (self.icon .. " "))
  end,
}

local FileName = {
  provider = function(self)
    if vim.bo.buftype == "terminal" then
      return "%{b:term_title}" .. " "
    elseif vim.bo.buftype == "quickfix" then
      return [[%{v:lua.require("kyoh86.plug.heirline.qftitle")()}]] .. " "
    end
    local filename = vim.fn.fnamemodify(self.filename, ":.")
    if filename == "" then
      filename = "[No Name]"
    end
    return filename .. " "
  end,
  hl = { bold = true },
}

return utils.insert(FileInfo, FileIcon, FileName)
