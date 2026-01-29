vim.g["fern#disable_default_mappings"] = 1
vim.g["g:fern#default_hidden"] = 1

local function open_fern()
  if vim.opt.buftype:get() ~= "" then
    vim.notify("is not file buffer", vim.log.levels.INFO)
    return "-"
  end
  local dirname = vim.fn.expand("%:p:h")
  if vim.fn.isdirectory(dirname) == 0 then
    vim.notify("is not dir", vim.log.levels.INFO)
    return "-"
  end
  return vim.fn.eval([[":\<C-u>edit "]]) .. dirname .. vim.fn.eval([["\<CR>"]])
end

---@type LazySpec
local spec = { {
  "lambdalisue/vim-fern-git-status",
  lazy = true,
}, {
  "lambdalisue/vim-fern-hijack",
  lazy = true,
}, {
  "lambdalisue/vim-fern",
  dependencies = {
    "vim-fern-git-status",
    "vim-fern-hijack",
  },
  config = function()
    vim.api.nvim_set_hl(0, "FernMarkedLine", { link = "PmenuSel" })

    vim.keymap.set("n", "<C-_>", "<cmd>Fern . -reveal=%<cr>", { silent = true, remap = false })
    vim.keymap.set("n", "-", open_fern, { silent = true, remap = true, expr = true })

    local au = require("kyoh86.lib.autocmd")
    au.group("kyoh86.plug.fern.init", true):hook("FileType", {
      pattern = "fern",
      callback = require("kyoh86.plug.fern.mode").setup,
    })
  end,
} }
return spec
