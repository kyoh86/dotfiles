autocmd BufRead,BufNewFile doc/*.txt if expand('%:p:h:h:t:s?vim-??:s?\.vim??:s?\.nvim??') ==# expand('%:t:s?\.txt??') | set filetype=help | endif
