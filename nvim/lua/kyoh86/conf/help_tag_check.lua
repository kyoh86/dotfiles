-- Function to check if a tag exists in the tags file
local function tag_exists(tag)
  local tags = vim.fn.taglist(tag)
  return #tags > 0
end

-- Function to get all ranges and texts for a specific syntax group in the current buffer
local function get_syntax_texts(syntax_group)
  local ranges = {}
  local lnum = 1
  while lnum <= vim.fn.line("$") do
    local col_start = 1
    while col_start <= vim.fn.col("$") do
      local syntax_id = vim.fn.synID(lnum, col_start, 1)
      local syntax_name = vim.fn.synIDattr(syntax_id, "name")
      if syntax_name == syntax_group then
        local col_end = col_start
        while col_end <= vim.fn.col("$") and vim.fn.synIDattr(vim.fn.synID(lnum, col_end, 1), "name") == syntax_group do
          col_end = col_end + 1
        end
        local text = vim.fn.getline(lnum):sub(col_start, col_end - 1)
        if not ranges[text] then
          ranges[text] = {}
        end
        table.insert(ranges[text], { lnum, col_start, col_end - 1 })
        col_start = col_end
      else
        col_start = col_start + 1
      end
    end
    lnum = lnum + 1
  end
  return ranges
end

-- Function to check all helpHyperTextJump links in the current buffer
local function check_help_tags()
  local jump_texts = get_syntax_texts("helpHyperTextJump")
  local qf_list = {}
  local diagnostics = {}

  for text, ranges in pairs(jump_texts) do
    local tag_valid = tag_exists(text)
    for _, range in ipairs(ranges) do
      table.insert(qf_list, {
        filename = vim.fn.expand("%"),
        lnum = range[1],
        col = range[2],
        text = text,
        type = tag_valid and "N" or "E",
      })
      table.insert(diagnostics, {
        lnum = range[1] - 1,
        col = range[2] - 1,
        end_col = range[3],
        message = text,
        severity = tag_valid and vim.diagnostic.severity.INFO or vim.diagnostic.severity.ERROR,
      })
    end
  end

  return qf_list, diagnostics
end

-- Command to run the check_help_tags function on specified help files and populate the quickfix list and/or diagnostics
local function create_check_command(command_name, filter_invalid)
  vim.api.nvim_create_user_command(command_name, function(opts)
    local qf_list = {}
    local namespace = vim.api.nvim_create_namespace("help_tag_checker")
    local files = opts.fargs

    for _, file in ipairs(files) do
      vim.cmd("edit " .. file)
      local bufnr = vim.api.nvim_get_current_buf()
      local file_qf_list, file_diagnostics = check_help_tags()
      if filter_invalid then
        file_qf_list = vim.tbl_filter(function(item)
          return item.type == "E"
        end, file_qf_list)
        file_diagnostics = vim.tbl_filter(function(item)
          return item.severity == vim.diagnostic.severity.ERROR
        end, file_diagnostics)
      end
      vim.list_extend(qf_list, file_qf_list)
      vim.diagnostic.set(namespace, bufnr, file_diagnostics)
    end

    -- Populate quickfix list
    vim.fn.setqflist(qf_list, "r")
    vim.cmd("copen")
  end, { nargs = "*" })
end

-- Create commands for checking help links
create_check_command("DiagnoseHelpLinks", false)
create_check_command("DiagnoseInvalidHelpLinks", true)
