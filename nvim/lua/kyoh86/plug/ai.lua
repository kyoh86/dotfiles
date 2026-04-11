---@type LazySpec[]
local specs = {
  {
    "ravitemer/mcphub.nvim",
    dependencies = { "plenary.nvim" },
    build = "bundled_build.lua",
    opts = {
      use_bundled_binary = true,
    },
  },
}
return specs
