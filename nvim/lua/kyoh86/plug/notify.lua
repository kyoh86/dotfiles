---@type LazySpec
local spec = {
  "rcarriga/nvim-notify",
  config = function()
    vim.notify = require("notify")
    vim.api.nvim_set_hl(0, "NotifyERRORBorder", { link = "DiagnosticError" })
    vim.api.nvim_set_hl(0, "NotifyWARNBorder", { link = "DiagnosticWarn" })
    vim.api.nvim_set_hl(0, "NotifyINFOBorder", { link = "DiagnosticInfo" })
    vim.api.nvim_set_hl(0, "NotifyDEBUGBorder", { link = "DiagnosticHint" })
    vim.api.nvim_set_hl(0, "NotifyTRACEBorder", { link = "DiagnosticHint" })
    vim.api.nvim_set_hl(0, "NotifyERRORIcon", { link = "DiagnosticError" })
    vim.api.nvim_set_hl(0, "NotifyWARNIcon", { link = "DiagnosticWarn" })
    vim.api.nvim_set_hl(0, "NotifyINFOIcon", { link = "DiagnosticInfo" })
    vim.api.nvim_set_hl(0, "NotifyDEBUGIcon", { link = "DiagnosticHint" })
    vim.api.nvim_set_hl(0, "NotifyTRACEIcon", { link = "DiagnosticHint" })
    vim.api.nvim_set_hl(0, "NotifyERRORTitle", { link = "DiagnosticError" })
    vim.api.nvim_set_hl(0, "NotifyWARNTitle", { link = "DiagnosticWarn" })
    vim.api.nvim_set_hl(0, "NotifyINFOTitle", { link = "DiagnosticInfo" })
    vim.api.nvim_set_hl(0, "NotifyDEBUGTitle", { link = "DiagnosticHint" })
    vim.api.nvim_set_hl(0, "NotifyTRACETitle", { link = "DiagnosticHint" })
  end,
}
return spec
