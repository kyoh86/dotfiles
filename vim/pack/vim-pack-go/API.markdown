
Public API for gopher.vim. This is not stable yet!

This file is generated using the mkapi script

[gopher.vim](autoload/gopher.vim)
---------------------------------
Various common functions, or functions that don't have a place elsewhere.

    gopher#error(msg, ...)
      Output an error message to the screen. The message can be either a list or a
      string; every line will be echomsg'd separately.

    gopher#info(msg, ...)
      Output an informational message to the screen. The message can be either a
      list or a string; every line will be echomsg'd separately.

[buf.vim](autoload/gopher/buf.vim)
----------------------------------
Utilities for working with buffers.

    gopher#buf#list()
      Get a list of all Go bufnrs.

    gopher#buf#doall(cmd)
      Run a command on every Go buffer and restore the position to the active
      buffer.

[coverage.vim](autoload/gopher/coverage.vim)
--------------------------------------------
Implement :GoCoverage.

    gopher#coverage#complete(lead, cmdline, cursor)
      Complete the special flags and some common flags people might want to use.

    gopher#coverage#do(...)
      Apply or clear coverage highlights.

    gopher#coverage#clear_hi()
      Clear any existing highlights for the current buffer.

    gopher#coverage#stop()
      Stop coverage mode.


[str.vim](autoload/gopher/str.vim)
----------------------------------
Utilities for working with strings.

    gopher#str#has_suffix(s, suffix)
      Report if s ends with suffix.

[go.vim](autoload/gopher/go.vim)
--------------------------------
Utilities for working with Go files.

    gopher#go#package()
      Get the package path for the file in the current buffer.

    gopher#go#packagepath()
      Get path to file in current buffer as package/path/file.go

    gopher#go#add_build_tags(flag_list)
      Add g:gopher_build_tags to the flag_list; will be merged with existing tags
      (if any).


[compl.vim](autoload/gopher/compl.vim)
--------------------------------------
Some helpers to work with commandline completion.

    gopher#compl#filter(lead, list)
      Return a copy of the list with only the items starting with lead.

[init.vim](autoload/gopher/init.vim)
------------------------------------
Initialisation of the plugin.

    gopher#init#config()
      Initialize config values.


[system.vim](autoload/gopher/system.vim)
----------------------------------------
Utilities for working with the external programs and the OS.

    gopher#system#run(cmd, ...)
      Run an external command.
      cmd must be a list, one argument per item. Every list entry will be
      automatically shell-escaped
      An optional second argument is passed to stdin.

    gopher#system#pathsep()
      Get the path separator for this platform.

    gopher#system#join(l, ...)
      Join a list of commands to a string, escaping any shell meta characters.

    gopher#system#sanitize_cmd(cmd)
      Remove v:null from the command, makes it easier to build commands:
      gopher#system#run(['gosodoff', (a:error ? '-errcheck' : v:null)])
      Without the filter an empty string would be passed.
