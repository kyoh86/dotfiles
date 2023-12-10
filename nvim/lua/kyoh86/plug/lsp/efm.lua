-- efm-langserverの設定セットを作ってる人がいるので、参考にすると良い
-- https://github.com/creativenull/efmls-configs-nvim

local stylua = {
  -- https://github.com/johnnymorganz/stylua
  prefix = "stylua",
  formatCanRange = true,
  formatCommand = string.format("stylua --color Never ${--range-start:charStart} ${--range-end:charEnd} --config-path %q -", vim.env.XDG_CONFIG_HOME .. "/stylua/stylua.toml"),
  formatStdin = true,
  rootMarkers = { "stylua.toml", ".stylua.toml" },
}

local scalafmt = {
  -- https://scalameta.org/scalafmt/docs/installation.html#editor-integration
  prefix = "scalafmt",
  formatCommand = "scalafmt --stdin --non-interactive",
  formatCanRange = true,
  formatStdin = true,
}

local actionlint = {
  -- https://github.com/rhysd/actionlint
  prefix = "actionlint",
  lintSource = "efm/actionlint",
  lintCommand = 'actionlint -no-color -oneline -stdin-filename "${INPUT}" -',
  lintStdin = true,
  lintFormats = {
    "%f:%l:%c: %.%#: SC%n:%trror:%m",
    "%f:%l:%c: %.%#: SC%n:%tarning:%m",
    "%f:%l:%c: %.%#: SC%n:%tnfo:%m",
    "%f:%l:%c: %m",
  },
  requireMarker = true,
  rootMarkers = { ".github/" },
}

local markdownlint = {
  -- https://github.com/DavidAnson/markdownlint
  prefix = "markdownlint",
  lintSource = "efm/markdownlint",
  lintCommand = "markdownlint --stdin",
  lintIgnoreExitCode = true,
  lintStdin = true,
  lintFormats = { "%f:%l:%c %m", "%f:%l %m", "%f: %l: %m" },
}

local textlint = {
  -- https://textlint.github.io/
  prefix = "textlint",
  lintSource = "efm/textlint",
  lintCommand = "textlint --no-color --format compact --stdin --stdin-filename ${INPUT}",
  lintStdin = true,
  lintFormats = { "%.%#: line %l, col %c, %trror - %m", "%.%#: line %l, col %c, %tarning - %m" },
  rootMarkers = { ".textlintrc", ".textlintrc.js", ".textlintrc.json", ".textlintrc.yml", ".textlintrc.yaml" },
}

local prettier = {
  -- https://github.com/prettier/prettier
  prefix = "prettier",
  formatCanRange = true,
  formatCommand = "prettier --stdin --stdin-filepath '${INPUT}' ${--range-start:charStart} ${--range-end:charEnd} ${--tab-width:tabSize} ${--use-tabs:!insertSpaces}",
  formatStdin = true,
  rootMarkers = {
    ".prettierrc",
    ".prettierrc.json",
    ".prettierrc.js",
    ".prettierrc.yml",
    ".prettierrc.yaml",
    ".prettierrc.json5",
    ".prettierrc.mjs",
    ".prettierrc.cjs",
    ".prettierrc.toml",
    "prettier.config.js",
    "prettier.config.cjs",
    "prettier.config.mjs",
  },
}

return {
  init_options = {
    documentFormatting = true,
    documentRangeFormatting = true,
    -- hover = true,
    -- documentSymbol = true,
    codeAction = true,
    -- completion = true,
  },
  settings = {
    languages = {
      javascript = { prettier },
      javascriptreact = { prettier },
      lua = { stylua },
      markdown = { textlint, markdownlint },
      scala = { scalafmt },
      typescript = { prettier },
      typescriptreact = { prettier },
      yaml = { actionlint },
    },
  },
}
