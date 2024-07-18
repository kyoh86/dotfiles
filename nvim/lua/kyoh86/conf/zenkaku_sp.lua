--- 全角空白のハイライトを切り替える

-- ハイライトを用意
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("kyoh86-conf-zenkaku-sp", { clear = true }),
  callback = function()
    kyoh86.ensure("momiji", function(m)
      vim.api.nvim_set_hl(0, "ZenkakuSpace", { bg = m.colors.lightred })
    end)
  end,
})
vim.api.nvim_set_hl(0, "ZenkakuSpace", { link = "Error" })

local match_id = -1

local function toggleZenkakuSpace()
  if match_id ~= -1 then
    -- ハイライトされている場合、解除
    vim.fn.matchdelete(match_id)
    match_id = -1
  else
    -- 全角空白をハイライト
    match_id = vim.fn.matchadd("ZenkakuSpace", "　")
  end
end

-- map
vim.keymap.set("n", "<leader>iz", toggleZenkakuSpace, { noremap = true, silent = true })
