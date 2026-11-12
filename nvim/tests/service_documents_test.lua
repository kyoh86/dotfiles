-- Exercise the real Neovim URI autocmds and picker actions with a fake service.
vim.opt.rtp:prepend(vim.fn.fnamemodify("nvim", ":p"))
vim.cmd.runtime("lua/kyoh86/conf/service_documents.lua")

local routes = {}
local function response(service, operation, handler)
  routes[service .. "/" .. operation] = handler
end

vim.system = function(argv, opts)
  local handler = assert(routes[argv[2] .. "/" .. argv[3]])
  local payload = opts.stdin and vim.json.decode(opts.stdin)
  local result = handler(argv, payload)
  return {
    wait = function()
      if type(result) == "string" then
        return { code = 1, stderr = result }
      end
      return { code = 0, stdout = vim.json.encode(result) }
    end,
  }
end

local function equal(expected, actual)
  assert(vim.deep_equal(expected, actual), vim.inspect({ expected = expected, actual = actual }))
end

local function check()
  local fields = { title = 'Title "quoted"', scope = "private", draft = true, tags = { "dev" }, groups = {}, body = "text\n" }
  response("docbase", "read", function(args)
    assert(vim.list_contains(args, "17"))
    return { fields = fields }
  end)
  local saves = 0
  response("docbase", "write", function(args, payload)
    saves = saves + 1
    equal(fields, payload.original)
    equal("edited\n", payload.fields.body)
    if saves == 1 then
      assert(vim.list_contains(args, "--template"))
      return "docbase: HTTP 503"
    elseif saves == 2 then
      assert(vim.list_contains(args, "--template"))
    else
      assert(vim.list_contains(args, "--id"))
      assert(not vim.list_contains(args, "--template"))
    end
    fields = payload.fields
    return { id = "42", fields = fields }
  end)
  local P = require("kyoh86.lib.pick")
  local choose, actions
  P.register = function(name, _, _, callback)
    P[name] = callback
  end
  P.cli = function(_, args, decode, opts)
    choose = function()
      local result = args[2] == "docbase" and { { id = 17, title = "Template" } } or { { _id = args[3] == "books" and "book:x" or "tag:x", name = "Fixture" } }
      opts.choose(decode(vim.json.encode(result))[1])
    end
    actions = opts.actions
  end
  require("kyoh86.lib.pick.services").setup()
  P.docbase_templates()
  choose()
  local buf = vim.api.nvim_get_current_buf()
  equal("acwrite", vim.bo[buf].buftype)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  equal("text", lines[#lines - 1])
  vim.api.nvim_buf_set_lines(buf, -3, -2, false, { "edited" })
  local ok, message = pcall(vim.cmd.write)
  assert(not ok and tostring(message):find("HTTP 503", 1, true))
  assert(vim.bo[buf].modified)
  equal("edited", vim.api.nvim_buf_get_lines(buf, -3, -2, false)[1])
  vim.cmd.write()
  equal("docbase://post;domain=wacul&postId=42", vim.api.nvim_buf_get_name(buf))
  assert(not vim.bo[buf].modified)
  vim.cmd.write()
  equal(3, saves)

  local metadata = { bookId = "book:old", status = "none", tags = {} }
  response("inkdrop", "read", function()
    return { fields = { title = "Note", body = "old" }, metadata = metadata }
  end)
  response("inkdrop", "metadata", function(_, payload)
    if payload.action == "book" then
      metadata.bookId = payload.value
    elseif payload.action == "add_tag" then
      metadata.tags = { payload.value }
    elseif payload.action == "remove_tag" then
      metadata.tags = {}
    else
      metadata.status = payload.value
    end
    return { metadata = metadata }
  end)
  P.cli = function(_, _, decode, opts)
    choose = function()
      opts.choose(decode(vim.json.encode({ { _id = "note:test", title = "Note" } }))[1])
    end
  end
  P.inkdrop_note()
  choose()
  buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 2, 3, false, { "unsaved" })
  P.cli = function(_, _, _, opts)
    actions = opts.actions
  end
  P.inkdrop_book()
  actions[1].run({ { id = "book:x" } })
  P.inkdrop_tag()
  actions[1].run({ { id = "tag:x" } })
  equal({ "tag:x" }, vim.b[buf].inkdrop_note_tag_ids)
  actions[2].run({ { id = "tag:x" } })
  P.start = function(_, _, opts)
    actions = opts.actions
  end
  P.inkdrop_status()
  actions[1].run({ { filter = { status = "active" } } })
  equal("book:x", vim.b[buf].inkdrop_note_book_id)
  equal("active", vim.b[buf].inkdrop_note_status)
  equal({}, vim.b[buf].inkdrop_note_tag_ids)
  assert(vim.bo[buf].modified)
  response("inkdrop", "write", function(_, payload)
    equal("old", payload.original.body)
    equal("unsaved", payload.fields.body)
    return { fields = payload.fields, metadata = metadata }
  end)
  vim.cmd.write()
  assert(not vim.bo[buf].modified)
  print("PASS: service pickers, URI writes, failed save, template creation, Inkdrop metadata")
end

local ok, err = xpcall(check, debug.traceback)
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd.cquit()
end
vim.cmd("qa!")
