local helper = require("kyoh86.plug.ddu.helper")

--- Create caller for ddu#ui#do_action
---@param actionName string
local function ddu_ui_action(actionName)
  return function()
    kyoh86.fa.ddu.ui.do_action(actionName, vim.empty_dict())
  end
end

---@type LazySpec
local spec = {
  "Shougo/ddu-ui-ff",
  dependencies = { "Shougo/ddu.vim" },
  config = function()
    kyoh86.ensure("momiji", function(m)
      -- local m = require("momiji")
      vim.api.nvim_set_hl(0, "dduFilter", {
        fg = m.colors.lightgreen,
        bg = m.colors.black,
        bold = true,
        underline = true,
        italic = true,
      })

      vim.api.nvim_set_hl(0, "dduCursorLine", { bg = m.colors.lightgreen, fg = m.colors.black, bold = true })

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

    kyoh86.fa.ddu.custom.patch_global({
      ui = "ff",
      uiParams = {
        ff = {
          split = "floating",
          floatingBorder = "rounded",
          prompt = "▶ ",
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

    local function resize()
      local lines = vim.opt.lines:get()
      -- row = 'lines' minus below / 2
      -- WINBAR LINE = 1
      -- MESSAGE LINE = 1
      -- STATUS LINE = 1
      local height = math.min(30, lines - 12)
      local row = math.floor((lines - height - 3) * 0.5)
      local columns = vim.opt.columns:get()
      local width, col = math.floor(columns * 0.8), math.floor(columns * 0.1)
      local winWidth = math.floor(width / 2) - 1

      local conf = {
        winRow = row,
        winWidth = winWidth,
        winHeight = height,
        winCol = col,
        previewRow = row,
        previewHeight = height,
        previewWidth = winWidth,
        previewCol = col + winWidth + 2,
      }
      kyoh86.fa.ddu.custom.patch_global({
        uiParams = {
          ff = conf,
        },
      })
    end
    resize()

    local group = vim.api.nvim_create_augroup("kyoh86-plug-ddu-ui-ff", { clear = true })
    vim.api.nvim_create_autocmd("VimResized", {
      group = group,
      callback = resize,
    })
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = "ddu-ff",
      callback = function()
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
      end,
    })

    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = "ddu-ff-filter",
      callback = function()
        vim.opt_local.cursorline = false
        local imap = function(lh, rh, opt)
          local option = vim.tbl_extend("keep", opt or {}, { nowait = true, buffer = true, silent = true, remap = false })
          vim.keymap.set("i", lh, rh, option)
        end
        imap("<esc>", "<esc>dd<cmd>call ddu#ui#do_action('closeFilterWindow')<cr>")
        imap("<cr>", "<esc><cmd>call ddu#ui#do_action('leaveFilterWindow')<cr>")
        imap("<bs>", function()
          return vim.fn.col(".") <= 1 and "" or "<bs>"
        end, { expr = true, remap = true })
        imap("<C-A>", "<Home>")
        imap("<C-F>", "<Right>")
        imap("<C-B>", "<Left>")
        imap("<C-D>", "<Del>")
        imap("<C-H>", "<BS>", { remap = true })
      end,
    })
  end,
}
return spec
