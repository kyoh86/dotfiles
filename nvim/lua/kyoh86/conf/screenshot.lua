local screenshot = require("kyoh86.lib.screenshot")

local function paste_latest_screenshot_path()
  local path, err = screenshot.latest()
  if path == nil then
    if err ~= nil then
      vim.notify(err, vim.log.levels.WARN)
    else
      vim.notify("unknown error from screenshot.latest", vim.log.levels.WARN)
    end
    return
  end

  vim.fn.setreg("+", path)

  local mode = vim.api.nvim_get_mode().mode
  if mode:sub(1, 1) == "i" then
    vim.api.nvim_paste(path, true, -1)
    return
  end

  vim.api.nvim_put({ path }, "c", true, true)
end

vim.keymap.set({ "n", "i" }, "<leader>ss", paste_latest_screenshot_path, { desc = "最新スクショのパスを貼り付ける" })
