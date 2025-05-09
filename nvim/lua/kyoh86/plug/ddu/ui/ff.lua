---@type LazySpec
local spec = {
  "Shougo/ddu-ui-ff",
  dependencies = { "ddu.vim" },
  config = function()
    require("kyoh86.lib.scheme").onSchemeChanged(function(colors_name)
      kyoh86.ensure(colors_name, function(m)
        vim.api.nvim_set_hl(0, "dduFilter", {
          fg = m.colors.brightgreen,
          bg = m.colors.black,
          bold = true,
          underline = true,
          italic = true,
          force = true,
        })

        vim.api.nvim_set_hl(0, "dduCursorLine", { bg = m.colors.brightgreen, fg = m.colors.black, bold = true, force = true })

        vim.api.nvim_set_hl(0, "dduSelectedSign", { fg = m.colors.yellow, bold = true, force = true })

        vim.api.nvim_set_hl(0, "dduPrompt", {
          fg = m.colors.brightgreen,
          bg = m.colors.black,
          force = true,
        })
        vim.api.nvim_set_hl(0, "dduBorder", {
          fg = m.colors.brightgreen,
          force = true,
        })
      end, function()
        vim.api.nvim_set_hl(0, "dduFilter", { link = "Normal", force = true })
        vim.api.nvim_set_hl(0, "dduPrompt", { link = "Normal", force = true })
        vim.api.nvim_set_hl(0, "dduBorder", { link = "Normal", force = true })
      end)
    end, true)

    vim.fn["ddu#custom#patch_global"]({
      ui = "ff",
      uiOptions = {
        ff = {
          filterPrompt = "󰈲  ",
        },
      },
      uiParams = {
        ff = {
          -- sizes >>>
          previewHeight = "min([70, &lines - 8])",
          previewCol = "&columns / 2",
          previewWidth = "&columns / 2",
          -- <<< sizes

          onPreview = vim.fn["denops#callback#register"](function(args)
            vim.wo[args.previewWinId].cursorline = false
          end),
          split = "tab",
          highlights = {
            filterText = "dduFilter",
            floating = "Normal",
            floatingCursorLine = "dduCursorLine",
            floatingBorder = "dduBorder",
            prompt = "dduPrompt",
          },
          autoAction = {
            name = "preview",
          },
          previewSplit = "vertical",
          previewWindowOptions = {
            { "&signcolumn", "no" },
            { "&foldcolumn", 0 },
            { "&foldenable", 0 },
            { "&number", 0 },
            { "&wrap", 0 },
            { "&scrolloff", 0 },
          },
          displayTree = true,
        },
      },
    })

    local augroup = vim.api.nvim_create_augroup("kyoh86-plug-ddu-ui-ff", { clear = true })
    vim.fn.sign_define("dduSelected", { text = "✔", texthl = "dduSelectedSign" })

    local f = require("kyoh86.lib.func")

    local redraw = f.vind_all(vim.fn["ddu#ui#do_action"], "redraw", { method = "uiRedraw" })
    vim.api.nvim_create_autocmd("VimResized", {
      group = augroup,
      callback = redraw,
    })

    local function ddu_ui_action(actionName, ...)
      local args = { ... }
      return f.bind_all(vim.fn["ddu#ui#do_action"], actionName, #args == 0 and vim.empty_dict() or args[1])
    end

    vim.api.nvim_create_autocmd("FileType", {
      group = augroup,
      pattern = "ddu-ff",
      callback = function(ev)
        vim.opt_local.signcolumn = "auto"

        local nmap = function(lh, rh)
          vim.keymap.set("n", lh, rh, { nowait = true, buffer = true, silent = true, remap = false })
        end
        nmap("<c-p>", "<nop>")
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
        nmap("<", ddu_ui_action("collapseItem"))
        nmap("+", ddu_ui_action("chooseAction"))

        local pendingScroll = "<plug>(kyoh86-pending-scroll)"
        local scrollMode = "<plug>(kyoh86-scroll)"

        vim.keymap.set("n", "<c-p><c-y>", scrollMode .. "<c-y>" .. pendingScroll, { buffer = true, remap = true })
        vim.keymap.set("n", "<c-p><c-e>", scrollMode .. "<c-e>" .. pendingScroll, { buffer = true, remap = true })
        vim.keymap.set("n", "<c-p><c-d>", scrollMode .. "<c-d>" .. pendingScroll, { buffer = true, remap = true })
        vim.keymap.set("n", "<c-p><c-u>", scrollMode .. "<c-u>" .. pendingScroll, { buffer = true, remap = true })

        vim.keymap.set("n", pendingScroll .. "<c-y>", scrollMode .. "<c-y>" .. pendingScroll, { buffer = true, remap = true })
        vim.keymap.set("n", pendingScroll .. "<c-e>", scrollMode .. "<c-e>" .. pendingScroll, { buffer = true, remap = true })
        vim.keymap.set("n", pendingScroll .. "<c-d>", scrollMode .. "<c-d>" .. pendingScroll, { buffer = true, remap = true })
        vim.keymap.set("n", pendingScroll .. "<c-u>", scrollMode .. "<c-u>" .. pendingScroll, { buffer = true, remap = true })

        vim.keymap.set("n", pendingScroll, "<nop>", { buffer = true, remap = false })

        nmap(scrollMode .. "<c-y>", ddu_ui_action("previewExecute", { command = [[execute "normal! \<c-y>"]] }))
        nmap(scrollMode .. "<c-e>", ddu_ui_action("previewExecute", { command = [[execute "normal! \<c-e>"]] }))
        nmap(scrollMode .. "<c-d>", ddu_ui_action("previewExecute", { command = [[execute "normal! \<c-d>"]] }))
        nmap(scrollMode .. "<c-u>", ddu_ui_action("previewExecute", { command = [[execute "normal! \<c-u>"]] }))
        nmap("<c-p><c-p>", ddu_ui_action("toggleAutoAction"))

        local pendingSelect = "<plug>(kyoh86-pending-select)"
        local selectMode = "<plug>(kyoh86-select)"
        vim.keymap.set("n", "<tab>", selectMode .. pendingSelect, { buffer = true, remap = true })
        vim.keymap.set("n", pendingSelect .. "j", "j" .. selectMode .. pendingSelect, { buffer = true, remap = true })

        local toggleSelection = function()
          vim.fn["ddu#ui#do_action"]("toggleSelectItem")
          local placed = vim.fn.sign_getplaced(ev.buf, { group = "dduSelected", lnum = "." })
          if placed == nil or #placed[1].signs == 0 then
            vim.fn.sign_place(0, "dduSelected", "dduSelected", ev.buf, { lnum = "." })
          else
            for _, p in pairs(placed[1].signs) do
              vim.fn.sign_unplace("dduSelected", { buffer = ev.buf, id = p.id })
            end
          end
        end
        nmap(selectMode, toggleSelection)
        nmap("<space>", toggleSelection)
      end,
    })
  end,
}
return spec
