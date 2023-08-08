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
  "lambdalisue/fern-git-status.vim",
  lazy = true,
}, {
  "lambdalisue/fern-hijack.vim",
  lazy = true,
}, {
  "lambdalisue/fern.vim",
  dependencies = {
    "fern-git-status.vim",
    "fern-hijack.vim",
  },
  config = function()
    vim.api.nvim_set_hl(0, "FernMarkedLine", { link = "PmenuSel" })

    vim.keymap.set("n", "<C-_>", "<cmd>Fern . -reveal=%<cr>", { silent = true, remap = false })
    vim.keymap.set("n", "-", open_fern, { silent = true, remap = true, expr = true })

    local g = vim.api.nvim_create_augroup("kyoh86-plug-fern-mode", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      group = g,
      pattern = "fern",
      callback = require("kyoh86.plug.fern.mode").setup,
    })
  end,
} }
return spec
