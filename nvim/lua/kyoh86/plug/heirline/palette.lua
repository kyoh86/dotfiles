--- heirlineの色管理

local M = {
  modes = {},
  palette = {},
}

function M.mode_colors()
  return M.modes[vim.fn.mode(0)]
end

function M.info()
  return { bg = M.palette.blue, fg = M.palette.black }
end

function M.warn()
  return { bg = M.palette.yellow, fg = M.palette.black }
end

function M.error()
  return { bg = M.palette.red, fg = M.culor("black") }
end

function M.set(palette)
  for name, color in pairs(palette) do
    M.palette[name] = color[1]
  end
  M.modes = {
    n = { deep = M.palette.green, light = M.palette.lightgreen },
    i = { deep = M.palette.blue, light = M.palette.lightblue },
    r = { deep = M.palette.cyan, light = M.palette.lightcyan },
    v = { deep = M.palette.yellow, light = M.palette.lightyellow },
    [""] = { deep = M.palette.yellow, light = M.palette.lightyellow },
    V = { deep = M.palette.yellow, light = M.palette.lightyellow },
    s = { deep = M.palette.magenta, light = M.palette.lightmagenta },
    S = { deep = M.palette.magenta, light = M.palette.lightmagenta },
    [""] = { deep = M.palette.magenta, light = M.palette.lightmagenta },
    R = { deep = M.palette.magenta, light = M.palette.lightmagenta },
    c = { deep = M.palette.red, light = M.palette.lightred },
    ["!"] = { deep = M.palette.red, light = M.palette.lightred },
    t = { deep = M.palette.red, light = M.palette.lightred },
  }
  require("heirline").load_colors(M.palette)
end

return M
