local function get_target_lines(args)
  if args.range == 1 then
    return { vim.fn.getline(args.line1 + 1) }
  elseif args.range == 2 then
    return vim.fn.getline(args.line1 + 1, args.line2 + 1) --[[@as string[] ]]
  end
  return { vim.fn.getline(".") }
end

local function decode_line(line)
  local sh = #line % 4
  if sh > 0 then
    line = line .. string.rep("=", sh)
  end
  return vim.base64.decode(line)
end

local function encode_line(line, bang)
  if bang then
    return string.gsub(vim.base64.encode(line), "=*$", "")
  end
  return vim.base64.encode(line)
end

vim.api.nvim_create_user_command("Base64Decode", function(args)
  local lines = get_target_lines(args)
  for _, line in ipairs(lines) do
    vim.print(decode_line(line))
  end
end, { force = true, range = true, nargs = 0 })

vim.api.nvim_create_user_command("Base64Encode", function(args)
  local lines = get_target_lines(args)
  for _, line in ipairs(lines) do
    vim.print(encode_line(line, args.bang))
  end
end, { force = true, range = true, nargs = 0, bang = true })
