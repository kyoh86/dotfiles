autocmd BufRead,BufNewFile */doc/*.txt,*/doc/*.jax if expand('%:p:h:h:t:s?^vim-??:s?\.vim$??:s?\.nvim$??') ==# expand('%:t:s?\.txt??') | set filetype=help | endif
autocmd BufRead,BufNewFile */nvim/doc/*.txt,*/doc/*.jax set filetype=help
