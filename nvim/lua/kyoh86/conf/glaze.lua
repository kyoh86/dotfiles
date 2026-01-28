local cmd = vim.api.nvim_create_user_command

cmd("GlazeList", function()
  for key, value in require("kyoh86.lib.glaze").each() do
    vim.print(key .. ": " .. vim.json.encode(value))
  end
end, {
  desc = "Show glazed values",
})

cmd("GlazeReset", function()
  require("kyoh86.lib.glaze").reset()
end, {
  desc = "Clear all glazed values",
})

cmd("GlazeDelete", function(args)
  require("kyoh86.lib.glaze").del(args.fargs[1])
end, {
  desc = "Clear all glazed values",
  nargs = 1,
})
