return {
  condition = function()
    return require("kyoh86.lib.gin_buffer_sources").source_label() ~= nil
  end,
  provider = function()
    return " " .. require("kyoh86.lib.gin_buffer_sources").source_label() .. " "
  end,
  hl = { bold = true, bg = "yellow", fg = "black" },
}
