local uv = vim.uv
local group = vim.api.nvim_create_augroup("kyoh86.zsh_history", { clear = true })
local snapshots = {}

local function read(path)
  local stat, err, code = uv.fs_stat(path)
  if not stat then
    if code == "ENOENT" then
      return nil
    end
    error(err, 0)
  end
  if stat.type ~= "file" then
    error("Not a regular zsh history file: " .. path, 0)
  end
  local fd = assert(io.open(path, "rb"))
  local data, read_err = fd:read("*a")
  fd:close()
  return assert(data, read_err), stat
end

vim.api.nvim_create_autocmd({ "BufReadCmd", "BufNewFile" }, {
  group = group,
  pattern = ".zsh_history",
  callback = function(event)
    local path = vim.fn.resolve(vim.fn.fnamemodify(event.file, ":p"))
    local raw = read(path)
    local text = raw or ""
    if text:sub(-1) == "\131" then
      error("Truncated metafied zsh history", 0)
    end
    text = text:gsub("\131(.)", function(byte)
      return string.char(bit.bxor(byte:byte(), 0x20))
    end)
    local newline = text:sub(-1) == "\n"
    if newline then
      text = text:sub(1, -2)
    end
    local opts = vim.bo[event.buf]
    opts.buftype, opts.swapfile, opts.fixendofline = "acwrite", false, false
    vim.api.nvim_buf_set_lines(event.buf, 0, -1, false, vim.split(text, "\n", { plain = true }))
    opts.endofline, opts.modified, opts.filetype = newline or raw == nil, false, "zsh_history.zsh"
    snapshots[event.buf] = { path = path, raw = raw }
  end,
})

vim.api.nvim_create_autocmd("BufWriteCmd", {
  group = group,
  pattern = ".zsh_history",
  callback = function(event)
    local name = vim.fn.fnamemodify(event.file, ":p")
    local path = vim.fn.resolve(name)
    local snapshot = snapshots[event.buf]
    if not snapshot or snapshot.path ~= path then
      error("Reload this zsh history file before saving", 0)
    end
    local raw, stat = read(path)
    if raw ~= snapshot.raw then
      error("zsh history changed on disk. Save a copy of your edits before reloading.", 0)
    end

    local text = table.concat(vim.api.nvim_buf_get_lines(event.buf, 0, -1, false), "\n")
    if vim.bo[event.buf].endofline then
      text = text .. "\n"
    end
    local encoded = text:gsub("[%z\131-\162]", function(byte)
      return "\131" .. string.char(bit.bxor(byte:byte(), 0x20))
    end)
    if encoded ~= raw then
      local fd, temporary = uv.fs_mkstemp(path .. ".XXXXXX")
      if not fd then
        error(temporary, 0)
      end
      local ok, err = pcall(function()
        local written, write_err = uv.fs_write(fd, encoded, 0)
        if written ~= #encoded then
          error(write_err or "Incomplete history write", 0)
        end
        if stat then
          assert(uv.fs_fchmod(fd, bit.band(stat.mode, 511)))
        end
      end)
      local closed, close_err = uv.fs_close(fd)
      local replaced
      if ok and closed then
        -- Coordinate with zsh's default history lock while replacing the file.
        local lock = name .. ".LOCK"
        local lockfd, lock_err, lock_code = uv.fs_open(lock, "wx", 384)
        if lockfd then
          ok, err = pcall(function()
            if read(path) ~= raw then
              error("zsh history changed while saving. Save a copy of your edits before reloading.", 0)
            end
            replaced = assert(uv.fs_rename(temporary, path))
          end)
          uv.fs_close(lockfd)
          uv.fs_unlink(lock)
        else
          err = lock_code == "EEXIST" and "zsh history is locked. Retry when the shell has finished writing." or lock_err
        end
      end
      if not replaced then
        uv.fs_unlink(temporary)
        error(err or close_err, 0)
      end
    end
    snapshot.raw = encoded
    vim.bo[event.buf].modified = false
  end,
})

vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
  group = group,
  callback = function(event)
    snapshots[event.buf] = nil
  end,
})
