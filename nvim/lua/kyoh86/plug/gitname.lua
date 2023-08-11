---@type LazySpec
local spec = {
  "kyoh86/vim-gitname",
  init = function()
    vim.api.nvim_create_user_command("YankGitHubURL", function(args)
      vim.fn["gitname#yank#hub_url"]("branch", args)
    end, { range = true, bang = true })
    vim.api.nvim_create_user_command("YankGitHubPermanentURL", function(args)
      vim.fn["gitname#yank#hub_url"]("head", args)
    end, { range = true, bang = true })
    vim.api.nvim_create_user_command("YankName", function()
      vim.fn.setreg("+", vim.fn.expand("%"))
    end, { range = true, bang = true })
    vim.api.nvim_create_user_command("YankFullName", function()
      vim.fn.setreg("+", vim.fn.expand("%:p"))
    end, { range = true, bang = true })
    vim.api.nvim_create_user_command("YankGitRel", function()
      vim.fn["gitname#yank#git_rel"]()
    end, { range = true, bang = true })
    vim.keymap.set("n", "<leader>ygh", [[:call gitname#yank#hub_url("branch", {})]], { silent = true, desc = "copy bufer GitHub URL" })
    vim.cmd([[vnoremap <silent> <leader>ygh :call gitname#yank#hub_url("branch", { "range": 2 })<cr>]]) -- it cannot be mapped by vim.keymap
  end,
}
return spec
