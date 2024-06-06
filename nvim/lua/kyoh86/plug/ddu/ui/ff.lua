local func = require("kyoh86.lib.func")

--- Create caller for ddu#ui#do_action
---@param actionName string
local function ddu_ui_action(actionName)
  return func.bind_all(vim.fn["ddu#ui#do_action"], actionName, vim.empty_dict())
end

---@type LazySpec
local spec = {
  "Shougo/ddu-ui-ff",
  dependencies = { "ddu.vim" },
  config = function()
    kyoh86.ensure("momiji", function(m)
      vim.api.nvim_set_hl(0, "dduFilter", {
        fg = m.colors.lightgreen,
        bg = m.colors.black,
        bold = true,
        underline = true,
        italic = true,
      })

      vim.api.nvim_set_hl(0, "dduCursorLine", { bg = m.colors.lightgreen, fg = m.colors.black, bold = true })
      vim.api.nvim_set_hl(0, "dduSelectedSign", { fg = m.colors.yellow, bold = true })

      vim.api.nvim_set_hl(0, "dduPrompt", {
        fg = m.colors.lightgreen,
        bg = m.colors.black,
      })
      vim.api.nvim_set_hl(0, "dduBorder", {
        fg = m.colors.lightgreen,
      })
    end, function()
      vim.api.nvim_set_hl(0, "dduFilter", { link = "Normal" })
      vim.api.nvim_set_hl(0, "dduPrompt", { link = "Normal" })
      vim.api.nvim_set_hl(0, "dduBorder", { link = "Normal" })
    end)

    vim.fn["ddu#custom#patch_global"]({
      ui = "ff",
      uiParams = {
        ff = {
          -- sizes >>>
          winRow = "(&lines - min([70, &lines - 8]) - 3) / 2",
          previewRow = "(&lines - min([70, &lines - 8]) - 3) / 2",

          winHeight = "min([70, &lines - 8])",
          previewHeight = "min([70, &lines - 8])",

          winCol = "&columns / 10",
          previewCol = "&columns / 2",

          winWidth = "&columns * 4 / 10 - 2",
          previewWidth = "&columns * 4 / 10 - 2",
          -- <<< sizes

          onPreview = vim.fn["denops#callback#register"](function(args)
            vim.wo[args.previewWinId].cursorline = false
          end),
          split = "floating",
          floatingBorder = "rounded",
          prompt = "󰈲  ",
          highlights = {
            filterText = "dduFilter",
            floating = "Normal",
            floatingCursorLine = "dduCursorLine",
            floatingBorder = "dduBorder",
            prompt = "dduPrompt",
          },

          startAutoAction = true,
          autoAction = {
            name = "preview",
          },
          previewFloating = true,
          previewFloatingBorder = "single",
          previewSplit = "vertical",
          previewWindowOptions = {
            { "&signcolumn", "no" },
            { "&foldcolumn", 0 },
            { "&foldenable", 0 },
            { "&number", 0 },
            { "&wrap", 0 },
            { "&scrolloff", 0 },
          },
        },
      },
    })

    vim.fn.sign_define("dduSelected", { text = "✔", texthl = "dduSelectedSign" })
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = "ddu-ff",
      callback = function(ev)
        vim.opt_local.signcolumn = "auto"

        local nmap = function(lh, rh)
          vim.keymap.set("n", lh, rh, { nowait = true, buffer = true, silent = true, remap = false })
        end
        nmap("<c-w>", "<nop>")
        nmap("<c-o>", "<nop>")
        nmap("<c-j>", "<nop>")
        nmap(":", "<nop>")
        nmap("q", "<nop>")
        nmap("m", "<nop>")
        nmap("t", "<nop>")
        nmap(";", ":")

        nmap("/", ddu_ui_action("openFilterWindow"))
        nmap("<esc>", ddu_ui_action("quit"))
        nmap("<cr>", ddu_ui_action("itemAction"))
        nmap(">", ddu_ui_action("expandItem"))
        nmap("+", ddu_ui_action("chooseAction"))
        nmap("<C-y>", function()
          vim.fn["ddu#ui#do_action"]("previewExecute", { command = [[execute "normal! \<C-y>"]] })
        end)
        nmap("<C-e>", function()
          vim.fn["ddu#ui#do_action"]("previewExecute", { command = [[execute "normal! \<C-e>"]] })
        end)
        nmap("<C-d>", function()
          vim.fn["ddu#ui#do_action"]("previewExecute", { command = [[execute "normal! \<C-d>"]] })
        end)
        nmap("<C-u>", function()
          vim.fn["ddu#ui#do_action"]("previewExecute", { command = [[execute "normal! \<C-u>"]] })
        end)
        nmap("<space>", function()
          vim.fn["ddu#ui#do_action"]("toggleSelectItem")
          local placed = vim.fn.sign_getplaced(ev.buf, { group = "dduSelected", lnum = "." })
          if placed == nil or #placed[1].signs == 0 then
            vim.fn.sign_place(0, "dduSelected", "dduSelected", ev.buf, { lnum = "." })
          else
            for _, p in pairs(placed[1].signs) do
              vim.fn.sign_unplace("dduSelected", { buffer = ev.buf, id = p.id })
            end
          end
        end)
      end,
    })
  end,
}
return spec
