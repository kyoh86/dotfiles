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
    n = { deep = M.palette.green, bright = M.palette.brightgreen },
    i = { deep = M.palette.blue, bright = M.palette.brightblue },
    r = { deep = M.palette.cyan, bright = M.palette.brightcyan },
    v = { deep = M.palette.yellow, bright = M.palette.brightyellow },
    [""] = { deep = M.palette.yellow, bright = M.palette.brightyellow },
    V = { deep = M.palette.yellow, bright = M.palette.brightyellow },
    s = { deep = M.palette.magenta, bright = M.palette.brightmagenta },
    S = { deep = M.palette.magenta, bright = M.palette.brightmagenta },
    [""] = { deep = M.palette.magenta, bright = M.palette.brightmagenta },
    R = { deep = M.palette.magenta, bright = M.palette.brightmagenta },
    c = { deep = M.palette.red, bright = M.palette.brightred },
    ["!"] = { deep = M.palette.red, bright = M.palette.brightred },
    t = { deep = M.palette.red, bright = M.palette.brightred },
  }
  require("heirline").load_colors(M.palette)
end

return M
