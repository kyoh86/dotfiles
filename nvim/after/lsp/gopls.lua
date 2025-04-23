return {
  init_options = {
    usePlaceholders = true,
    semanticTokens = true,
    staticcheck = true,
    experimentalPostfixCompletions = true,
    directoryFilters = {
      "-node_modules",
    },
    analyses = {
      nilness = true,
      unusedparams = true,
      unusedwrite = true,
    },
    codelenses = {
      gc_details = true,
      test = true,
      tidy = true,
    },
    hints = {
      assignVariableTypes = true,
      compositeLiteralTypes = true,
      constantValues = true,
      parameterNames = true,
      rangeVariableTypes = true,
    },
  },
}
