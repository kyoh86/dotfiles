local func = require("kyoh86.lib.func")
---@type LazySpec
local spec = {
  "vim-skk/skkeleton",
  dependencies = { "denops.vim", "sakura", "momiji" },
  config = function()
    vim.fn["skkeleton#config"]({
      globalJisyo = "~/.local/share/skk/SKK-JISYO.L",
      markerHenkan = "❓",
      markerHenkanSelect = "❗",
      eggLikeNewline = true,
      immediatelyCancel = true,
    })
    vim.fn["skkeleton#register_kanatable"]("rom", {
      ["("] = { "（" },
      [")"] = { "）" },
    })
    local map = function(mode, key, operation)
      vim.fn["skkeleton#register_keymap"](mode, vim.keycode(key), operation)
    end
    map("input", "<space>", "henkanFirst")
    map("input", "<C-q>", "katakana")
    map("henkan", "<S-space>", "henkanBackward")

    require("kyoh86.lib.scheme").onSchemeChanged(function(colors_name)
      local palette = vim.g[colors_name .. "_palette"]
      local skk_mode_colors = {
        [""] = { bg = palette.blue[1], fg = palette.black[1] },
        hira = { bg = palette.yellow[1], fg = palette.black[1] }, -- ひらがな
        kata = { bg = palette.red[1], fg = palette.black[1] }, -- カタカナ
        hankata = { bg = palette.magenta[1], fg = palette.black[1] }, -- 半角カタカナ
        zenkaku = { bg = palette.green[1], fg = palette.black[1] }, -- 全角英数
        abbrev = { bg = palette.magenta[1], fg = palette.black[1] },
      }
      local disable_color = func.bind_all(vim.api.nvim_set_hl, 0, "CursorLineNr", { bg = palette.white[1], fg = palette.black[1] })
      local inserting = {
        i = true,
        R = true,
        s = true,
        S = true,
        [""] = true,
      }
      local apply_mode_color = function()
        if inserting[vim.fn.mode(0)] then
          local skk_mode = vim.fn["skkeleton#mode"]()
          vim.api.nvim_set_hl(0, "CursorLineNr", skk_mode_colors[skk_mode])
        else
          disable_color()
        end
      end
      disable_color()
      local skk_group = vim.api.nvim_create_augroup("kyoh86-plug-skk", { clear = true })
      vim.api.nvim_create_autocmd("ModeChanged", {
        group = skk_group,
        callback = apply_mode_color,
      })
      vim.api.nvim_create_autocmd("User", {
        group = skk_group,
        pattern = "skkeleton-mode-changed",
        callback = apply_mode_color,
      })
    end, true)
  end,
  keys = {
    { "<c-j>", "<plug>(skkeleton-toggle)", mode = { "i", "c" } },
  },
}
return spec
