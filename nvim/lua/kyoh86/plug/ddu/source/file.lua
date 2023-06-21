local helper = require("kyoh86.plug.ddu.helper")

local function files_or_gitls()
  local stat = vim.uv.fs_stat(".git")
  if stat and stat.type == "directory" then
    vim.fa.ddu.start({
      name = "file-ext",
      sources = { {
        name = "file_external",
        params = { cmd = { "git", "ls-files" } },
      } },
    })
  else
    vim.fa.ddu.start({
      name = "file-rec",
      sources = { {
        name = "file_rec",
      } },
    })
  end
end

---@type LazySpec
local spec = {
  "matsui54/ddu-source-file_external",
  config = function()
    -- setup source for files or gitls
    vim.keymap.set("n", "<leader>ff", files_or_gitls, { remap = false, desc = "Start ddu to list files or git-ls files" })
    helper.start_by("<leader>fgf", "file-ext", {
      sources = { {
        name = "file_external",
        params = { cmd = { "git", "ls-files" } },
      } },
    })

    helper.map_for_file("file-rec")
    helper.map_for_file("file-ext")

    -- setup source for nvim-configs
    helper.start_by("<leader><leader>c", "nvim-config", { sources = { { name = "file_rec", options = { path = vim.env.XDG_CONFIG_HOME } } } })
    helper.map_for_file("nvim-config")
  end,
  dependencies = { "Shougo/ddu.vim", "Shougo/ddu-kind-file", "Shougo/ddu-source-file_rec" },
}
return spec
