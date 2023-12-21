---@type LazySpec
local spec = {
  "delphinus/cellwidths.nvim",
  config = function()
    require("cellwidths").setup({
      name = "user/custom",
      fallback = function(cw)
        cw.load("default")

        cw.add({ 0x23FB, 0x23FE, 2 })
        cw.add({ 0xE000, 0xE00A, 2 })
        cw.add({ 0xE0A0, 0xE0A2, 2 })
        cw.add({ 0xE0A3, 0xE0A3, 2 })
        cw.add({ 0xE0B0, 0xE0B3, 2 })
        cw.add({ 0xE0B4, 0xE0C8, 2 })
        cw.add({ 0xE0CA, 0xE0CA, 2 })
        cw.add({ 0xE0CC, 0xE0D4, 2 })
        cw.add({ 0xE200, 0xE2A9, 2 })
        cw.add({ 0xE300, 0xE3EB, 2 })
        cw.add({ 0xE5FA, 0xE62D, 2 })
        cw.add({ 0xE62F, 0xE631, 2 })
        cw.add({ 0xE700, 0xE7C5, 2 })
        cw.add({ 0xEA60, 0xEBEB, 2 })
        cw.add({ 0xF000, 0xF2E0, 2 })
        cw.add({ 0xF300, 0xF314, 2 })
        cw.add({ 0xF317, 0xF31A, 2 })
        cw.add({ 0xF31D, 0xF32F, 2 })
        cw.add({ 0xF400, 0xF4A8, 2 })
        cw.add({ 0xF4A9, 0xF4A9, 2 })
        cw.add({ 0xF500, 0xFD46, 2 })

        cw.delete({ 0x25B2, 0x25B3 })
      end,
      build = ":CellWidthsRemove",
    })
  end,
}
return spec
