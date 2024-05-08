---@type LazySpec
local spec = {
  "kyoh86/denops-ollama.vim",
  config = function()
    -- vim.fn['denops#server#wait']()
    vim.fn["denops#plugin#wait_async"]("ollama", function()
      vim.fn["ollama#custom#patch_func_args"]("complete", { model = "codellama", baseUrl = "http://127.0.0.1:11434" })
    end)

    vim.api.nvim_create_user_command("OllamaStartChat", function()
      vim.fn["ollama#start_chat_in_ctx"]({
        model = "llama3:8b",
        context = {
          selection = true,
          buffers = vim
            .iter(vim.fn.getbufinfo({ buflisted = 1 }))
            :filter(function(buf)
              return vim.fn.getbufvar(buf.bufnr, "&buftype", "") == "" and buf.name ~= ""
            end)
            :map(function(buf)
              return {
                bufnr = buf.bufnr,
                name = buf.name,
              }
            end)
            :totable(),
        },
      })
    end, {})
  end,
  dependencies = { "denops.vim" },
}
return spec
