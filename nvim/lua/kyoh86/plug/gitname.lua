---@type LazySpec
local spec = {
  "kyoh86/vim-gitname",
  init = function()
    local func = require("kyoh86.lib.func")
    vim.api.nvim_create_user_command("YankGitHubURL", function(args)
      vim.fn["gitname#yank#hub_url"]("branch", args)
    end, { range = true, bang = true })
    vim.api.nvim_create_user_command("YankGitHubPermanentURL", function(args)
      vim.fn["gitname#yank#hub_url"]("head", args)
    end, { range = true, bang = true })
    vim.api.nvim_create_user_command("YankGitRel", func.bind_all(vim.fn["gitname#yank#git_rel"]), { range = true, bang = true })
    vim.api.nvim_create_user_command("YankName", function()
      vim.fn.setreg("+", vim.fn.expand("%"))
    end, { range = true, bang = true })
    vim.api.nvim_create_user_command("YankFullName", function()
      vim.fn.setreg("+", vim.fn.expand("%:p"))
    end, { range = true, bang = true })

    vim.keymap.set("n", "<leader>ygh", [[<cmd>call gitname#yank#hub_url("branch", {})]], { silent = true, desc = "バッファのGitHub URLをYankする" })
    vim.cmd([[vnoremap <silent> <leader>ygh <cmd>call gitname#yank#hub_url("branch", { "range": 2 })<cr>]]) -- it cannot be mapped by vim.keymap
  end,
}
return spec
