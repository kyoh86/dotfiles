vim.cmd[[packadd packer.nvim]]

local packer = require'packer'
packer.init({
  max_jobs=70,
})
packer.startup(function()
  use { 'wbthomason/packer.nvim', opt = true }

  -- Base                   ======================================================

  use {
    'nvim-lua/plenary.nvim',
    'nvim-lua/popup.nvim',
    'kyazdani42/nvim-web-devicons',
  }

  -- Visuals                 ==================================================

  use 'kyoh86/momiji'

  use {
    'lewis6991/gitsigns.nvim',
    requires = {
      'nvim-lua/plenary.nvim'
    },
    config = function()
      require('gitsigns').setup({
        keymaps = {
          ['n ]g'] = { expr = true, "&diff ? ']g' : '<cmd>lua require\"gitsigns\".next_hunk()<CR>'"},
          ['n [g'] = { expr = true, "&diff ? '[g' : '<cmd>lua require\"gitsigns\".prev_hunk()<CR>'"},
        }
      })
    end
  }

  use {
    'glepnir/galaxyline.nvim',
    branch = 'main',
    config = function() require'my-galaxyline' end,
    requires = {
      'lewis6991/gitsigns.nvim',
      'kyazdani42/nvim-web-devicons',
      'kyoh86/momiji',
    },
  }

  use {
    'kyoh86/gitstat.nvim',
    config = function()
      vim.g['gitstat#parts'] = 'branch,ahead,behind,sync,unmerged,staged,unstaged,untracked'
      vim.g['gitstat#blend'] = 10
      vim.cmd('highlight! GitStatWindow    guibg=' .. vim.g.momiji_colors.green  .. ' guifg=' .. vim.g.momiji_colors.black)
      vim.cmd('highlight! GitStatBranch    guibg=' .. vim.g.momiji_colors.green  .. ' guifg=' .. vim.g.momiji_colors.black)
      vim.cmd('highlight! GitStatRemote    guibg=' .. vim.g.momiji_colors.green  .. ' guifg=' .. vim.g.momiji_colors.black)
      vim.cmd('highlight! GitStatAhead     guibg=' .. vim.g.momiji_colors.yellow .. ' guifg=' .. vim.g.momiji_colors.black)
      vim.cmd('highlight! GitStatBehind    guibg=' .. vim.g.momiji_colors.yellow .. ' guifg=' .. vim.g.momiji_colors.black)
      vim.cmd('highlight! GitStatSync      guibg=' .. vim.g.momiji_colors.yellow .. ' guifg=' .. vim.g.momiji_colors.black)
      vim.cmd('highlight! GitStatUnmerged  guibg=' .. vim.g.momiji_colors.yellow .. ' guifg=' .. vim.g.momiji_colors.black)
      vim.cmd('highlight! GitStatStaged    guibg=' .. vim.g.momiji_colors.yellow .. ' guifg=' .. vim.g.momiji_colors.black)
      vim.cmd('highlight! GitStatUnstaged  guibg=' .. vim.g.momiji_colors.yellow .. ' guifg=' .. vim.g.momiji_colors.black)
      vim.cmd('highlight! GitStatUntracked guibg=' .. vim.g.momiji_colors.yellow .. ' guifg=' .. vim.g.momiji_colors.black)
      require 'gitstat'.show()
    end
  }

  use 'lambdalisue/readablefold.vim'

  use {
    'kyoh86/vim-cinfo',
    config = function()
      vim.api.nvim_set_keymap('n', '<leader>ic', '<plug>(cinfo-show-cursor)', {})
      vim.api.nvim_set_keymap('n', '<leader>ib', '<plug>(cinfo-show-buffer)', {})
      vim.api.nvim_set_keymap('n', '<leader>ih', '<plug>(cinfo-show-highlight)', {})
    end,
  }

  -- Fuzzy finder            ==================================================

  use {
    {
      'nvim-telescope/telescope.nvim',
      requires = {
        {'nvim-lua/popup.nvim'},
        {'nvim-lua/plenary.nvim'},
      },
      config = function() require('my-telescope') end,
    },

    {
      'kyoh86/telescope-windows.nvim',
      requires = {
        'nvim-telescope/telescope.nvim',
      },
      config = function()
        require('telescope').load_extension('windows')
      end
    },

    {
      'nvim-telescope/telescope-github.nvim',
      requires = {
        'nvim-telescope/telescope.nvim',
      },
      config = function()
        require('telescope').load_extension('gh')
        vim.api.nvim_set_keymap('n', '<leader>fgi', '<cmd>lua require("telescope").extensions.gh.issues()<cr>',  { noremap = true, silent = true })
        vim.api.nvim_set_keymap('n', '<leader>fgp', '<cmd>lua require("telescope").extensions.gh.pull_request()<cr>',  { noremap = true, silent = true })
      end
    },

    {
      'kyoh86/telescope-gogh.nvim',
      requires = {
        'nvim-telescope/telescope.nvim',
      },
      config = function()
        vim.api.nvim_set_keymap('n', '<leader>fp', '<cmd>lua require("telescope").extensions.gogh.list()<cr>',  { noremap = true, silent = true })
        vim.api.nvim_set_keymap('n', '<leader>fpl', '<cmd>lua require("telescope").extensions.gogh.list()<cr>',  { noremap = true, silent = true })
        vim.api.nvim_set_keymap('n', '<leader>fpr', '<cmd>lua require("telescope").extensions.gogh.repos()<cr>',  { noremap = true, silent = true })
        require('telescope').setup{
          extensions = {
            gogh = {
              shorten_path = false,
              keys = {
                list = {
                  cd   = 'default',
                  open = '<c-e>',
                  lcd  = nil,
                  tcd  = nil,
                },
                repos = {
                  get = '<cr>',
                  browse = '<c-o>',
                },
              }
            },
          }
        }
        require('telescope').load_extension('gogh')
      end
    },

    {
      "nvim-telescope/telescope-frecency.nvim",
      requires = {
        'nvim-telescope/telescope.nvim',
        'tami5/sql.nvim',
      },
      config = function()
        require"telescope".load_extension("frecency")
        vim.api.nvim_set_keymap('n', '<leader>fm', "<cmd>lua require('telescope').extensions.frecency.frecency()<cr>", {noremap = true, silent = true})
      end
    },
  }

  -- LSP                     ==================================================

  use {
    {'kabouzeid/nvim-lspinstall'},
    {
      'neovim/nvim-lspconfig',
      config = function() require 'my-lsp' end,
    }
  }

  -- Completion & Snippet    ==================================================

  use {
    {
      'hrsh7th/nvim-compe',
      config = function()
        vim.cmd[[inoremap <silent><expr> <c-x><c-s> compe#complete()]]
        vim.cmd[[inoremap <silent><expr> <cr>       compe#confirm('<cr>')]]
        vim.cmd[[inoremap <silent><expr> <c-e>      compe#close('<c-e>')]]
        vim.o.shortmess = vim.o.shortmess .. 'c'
        vim.o.completeopt = "menuone,noselect"
        require'compe'.setup {
          enabled = true;
          autocomplete = false;
          debug = false;
          min_length = 1;
          preselect = 'enable';
          throttle_time = 80;
          source_timeout = 200;
          incomplete_delay = 400;
          max_abbr_width = 100;
          max_kind_width = 100;
          max_menu_width = 100;
          documentation = true;

          source = {
            path = true;
            calc = true;
            vsnip = true;

            nvim_lsp = true;
            nvim_lua = true;
            buffer = false;
            omni = false;
          };
        }
      end,
    },
    {
      'golang/vscode-go',
      opt = true,
      ft = {'go'},
    },
    {
      'deerawan/vscode-elasticsearch-snippets',
      opt = true,
      ft = {'rest'},
    },
    'hrsh7th/vim-vsnip-integ',
    {
      'hrsh7th/vim-vsnip',
      config = function()
        vim.g.vsnip_snippet_dirs = {
          vim.fn.expand('~/.config/nvim/vsnip'),
          vim.fn.expand('~/.config/aia/vsnip'),
        }

        -- Expand or jump
        vim.cmd[[imap <expr> <C-l>   vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-l>']]
        vim.cmd[[smap <expr> <C-l>   vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-l>']]

        -- Jump forward or backward
        vim.cmd[[imap <expr> <tab>   vsnip#jumpable(1)   ? '<plug>(vsnip-jump-next)'      : '<tab>']]
        vim.cmd[[smap <expr> <tab>   vsnip#jumpable(1)   ? '<plug>(vsnip-jump-next)'      : '<tab>']]
        vim.cmd[[imap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<plug>(vsnip-jump-prev)'      : '<S-Tab>']]
        vim.cmd[[smap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<plug>(vsnip-jump-prev)'      : '<S-Tab>']]
      end,
      requires = {
        'golang/vscode-go',
      },
    },
  }

  -- Text handlers           ==================================================

  use {
    {'kana/vim-textobj-user'},
    {
      'kana/vim-textobj-line',
      requires = {'kana/vim-textobj-user'}
    },

    {
      'kana/vim-textobj-entire',
      requires = {'kana/vim-textobj-user'}
    },

    {
      'sgur/vim-textobj-parameter',
      requires = {'kana/vim-textobj-user'}
    },

    {
      'whatyouhide/vim-textobj-xmlattr',
      requires = {'kana/vim-textobj-user'}
    },
  }

  use {
    {
      'kana/vim-operator-user',
    },
    {
      'kana/vim-operator-replace',
      requires = {'kana/vim-operator-user'},
    },
    {
      'osyo-manga/vim-operator-jump_side',
      requires = {'kana/vim-operator-user'},
      config = function()
        -- textobj の先頭へ移動する
        vim.api.nvim_set_keymap('n', '[<leader>', '<plug>(operator-jump-head)', {})
        -- textobj の末尾へ移動する
        vim.api.nvim_set_keymap('n', ']<leader>', '<plug>(operator-jump-tail)', {})
      end,
    }
  }

  use {
    'machakann/vim-sandwich',
    config = function()
      -- ignore s instead of the cl
      vim.api.nvim_set_keymap('n', 's', '<nop>', { noremap = true })
      vim.api.nvim_set_keymap('x', 's', '<nop>', { noremap = true })

      --NOTE: silent! は vim.cmd じゃないと呼べないっぽい
      vim.cmd[[silent! nmap <unique><silent> sc <plug>(operator-sandwich-replace)<plug>(operator-sandwich-release-count)<plug>(textobj-sandwich-query-a)]]
      vim.cmd[[silent! nmap <unique><silent> scb <plug>(operator-sandwich-replace)<plug>(operator-sandwich-release-count)<plug>(textobj-sandwich-auto-a)]]
    end,
  }

  use {
    'machakann/vim-swap',
    config = function()
      vim.api.nvim_set_keymap('o', 'i,', '<plug>(swap-textobject-i)', {})
      vim.api.nvim_set_keymap('x', 'i,', '<plug>(swap-textobject-i)', {})
      vim.api.nvim_set_keymap('o', 'a,', '<plug>(swap-textobject-a)', {})
      vim.api.nvim_set_keymap('x', 'a,', '<plug>(swap-textobject-a)', {})
    end,
  }

  -- Integrations            ==================================================

  use {
    'jremmen/vim-ripgrep',
    cmd = 'Rg',
    config = function()
      vim.cmd[[cabbrev <expr> Rgi (getcmdtype() ==# ":" && getcmdline() ==# "Rgi") ? "Rg --no-ignore-vcs" : "Rgi"]]
      vim.cmd[[cabbrev <expr> Rga (getcmdtype() ==# ":" && getcmdline() ==# "Rga") ? "Rg --no-ignore"     : "Rga"]]
      vim.g.rg_highlight = true
      vim.g.rg_derive_root = true
    end,
  }

  use {
    {
      'kyoh86/vim-zenn-autocmd',
      config = function()
        vim.fn['zenn_autocmd#enable']()
      end
    },

    {
      'kyoh86/telescope-zenn.nvim',
      requires = {
        'nvim-telescope/telescope.nvim',
        'kyoh86/vim-zenn-autocmd',
      },
      config = function()
        require('telescope').load_extension('zenn')
        vim.api.nvim_exec([[
          augroup my-telescope-zenn-autocmd
            autocmd!
            autocmd User ZennEnter nnoremap <silent> <leader>zfa <cmd>Telescope zenn articles<cr>
            autocmd User ZennLeave silent! unnmap! <leader>zfa
          augroup end
        ]],false)
      end
    },

    {
      'kkiyama117/zenn-vim',
      requires = { 'kyoh86/vim-zenn-autocmd' },
      config = function()
        vim.g["zenn#article#edit_new_cmd"] = "edit"
        vim.api.nvim_exec([[
          command! -nargs=0 ZennUpdate call zenn#update()
          command! -nargs=* ZennPreview call zenn#preview(<f-args>)
          command! -nargs=0 ZennStopPreview call zenn#stop_preview()
          command! -nargs=* ZennNewArticle call zenn#new_article(<f-args>)
          command! -nargs=* ZennNewBook call zenn#new_book(<f-args>)
          augroup my-zenn-vim-autocmd
            autocmd!
            autocmd User ZennEnter nnoremap <silent> <leader>zna <cmd>ZennNewArticle<cr>
            autocmd User ZennLeave silent! unnmap! <leader>zna
          augroup end
        ]], false)
      end,
    },
  }

  use {
    'thinca/vim-quickrun',
    setup = function()
      vim.g.quickrun_no_default_key_mappings = 1
    end,
    config = function()
      vim.api.nvim_set_keymap('n', '<leader>r', '<plug>QuickRun -mode n<cr>', { silent = true, noremap = true })
      vim.api.nvim_set_keymap('v', '<leader>r', '<plug>QuickRun -mode v<cr>', { silent = true, noremap = true })
    end,
  }

  use {
    'tpope/vim-dispatch',
    {
      'vim-test/vim-test',
      requires = {'tpope/vim-dispatch'},
      config = function()
        vim.api.nvim_set_var('test#strategy', 'dispatch')
        vim.api.nvim_set_var('test#vimterminal#term_position', 'aboveleft')
        vim.api.nvim_set_keymap('n','<leader>tg', '<cmd>TestVisit<cr>',   { silent = true, noremap = true })
        vim.api.nvim_set_keymap('n','<leader>tt', '<cmd>TestNearest<cr>', { silent = true, noremap = true })
        vim.api.nvim_set_keymap('n','<leader>tf', '<cmd>TestFile<cr>',    { silent = true, noremap = true })
        vim.api.nvim_set_keymap('n','<leader>ta', '<cmd>TestSuite<cr>',   { silent = true, noremap = true })
        vim.api.nvim_set_keymap('n','<leader>tl', '<cmd>TestLast<cr>',    { silent = true, noremap = true })
      end,
    },
  }

  use {
    'kyoh86/vim-quotem',
    config = function()
      vim.api.nvim_set_keymap('v', '<leader>yb', '<plug>(quotem-named)', {})
      vim.api.nvim_set_keymap('v', '<leader>Yb', '<plug>(quotem-fullnamed)', {})
      vim.api.nvim_set_keymap('n', '<leader>yb', '<plug>(operator-quotem-named)', {})
      vim.api.nvim_set_keymap('n', '<leader>Yb', '<plug>(operator-quotem-fullnamed)', {})
    end,
  }

  use 'iberianpig/tig-explorer.vim'

  use {
    'tyru/open-browser-github.vim',
    requires = { 'tyru/open-browser.vim' }
  }

  use {
    'diepm/vim-rest-console',
    config = function()
      local option = {}
      option['--connect-timeout'] = 10
      option['--silent'] = ''
      vim.g.vrc_curl_opts = option
    end
  }

  -- Manipulate vim          ==================================================

  use {
    'kyoh86/vim-copy-buffer-name',
    config = function()
      vim.api.nvim_set_keymap('n', '<leader>y%', '<plug>(copy-buffer-name)', {})
      vim.api.nvim_set_keymap('n', '<leader>Y%', '<plug>(copy-buffer-full-name)', {})
    end,
  }

  use {
    'qpkorr/vim-bufkill',
    setup = function()
      vim.api.nvim_set_var('BufKillCreateMappings', 0)
    end,
  }

  use {
    'lambdalisue/edita.vim',
    config = function()
      vim.g['edita#opener'] = 'new'
    end,
  }

  use 'tyru/empty-prompt.vim'

  use {
    'lambdalisue/fern.vim',
    -- config is in init.vim
    requires = {
      { 'lambdalisue/fern-git-status.vim' }        ,
      { 'lambdalisue/fern-hijack.vim' }            ,
      { 'lambdalisue/fern-renderer-nerdfont.vim' } ,
    },
    setup = function()
      vim.api.nvim_set_var('fern#disable_default_mappings', 1)
    end,
    config = function()
      vim.cmd[[
        runtime! etc/my-fern-mode.vim
        runtime! etc/my-fern.vim
      ]]
    end,
  }

  use 'tyru/capture.vim'

  use {
    'Asheq/close-buffers.vim',
    config = function()
      vim.api.nvim_set_keymap('n', '<C-q>', '<cmd>Bdelete menu<cr>', {noremap = true, silent = true})
    end
  }

  use {
    't9md/vim-choosewin',
    config = function()
      vim.api.nvim_set_keymap('n', '<leader>wf', '<plug>(choosewin)', {})
    end,
  }
  use {
    'kyoh86/curtain.nvim',
    config = function()
      vim.api.nvim_set_keymap('n', '<leader>wr', '<plug>(curtain-start)', {})
    end,
  }

  use { 'bfredl/nvim-miniyank',
    config = function()
      vim.api.nvim_set_keymap('', 'p', '<plug>(miniyank-autoput)', {})
      vim.api.nvim_set_keymap('', 'P', '<plug>(miniyank-autoPut)', {})
    end,
  }

  -- Languages               ==================================================

  -- - go
  use {
    'kyoh86/vim-go-filetype',
    'kyoh86/vim-go-scaffold',
    'kyoh86/vim-go-testfile',
    'kyoh86/vim-go-coverage',
    'mattn/vim-goimports',
  }

  -- - markdown
  use {
    {
      'iamcco/markdown-preview.nvim',
      run = 'cd app && yarn install',
      ft = 'markdown',
    },
    { 'dhruvasagar/vim-table-mode', ft = 'markdown' },
    {
      'kyoh86/markdown-image.nvim',
      ft = 'markdown',
      config = function()
        vim.api.nvim_set_keymap('n', '<leader>mir', [[<cmd>lua require('markdown-image').replace(require('markdown-image.gcloud').new('post.kyoh86.dev', 'post', 'post.kyoh86.dev', 'image'))<cr>]], {noremap = true})
        vim.api.nvim_set_keymap('n', '<leader>mip', [[<cmd>lua require('markdown-image').put(require('markdown-image.gcloud').new('post.kyoh86.dev', 'post', 'post.kyoh86.dev', 'image'))<cr>]], {noremap = true})
      end,
    },
  }

  -- - others
  use 'jparise/vim-graphql'
  use { 'z0mbix/vim-shfmt', ft = {'sh', 'bash', 'zsh'} }
  use { 'lambdalisue/vim-backslash', ft = 'vim' }
  use 'glench/vim-jinja2-syntax'
  use 'briancollins/vim-jst'
  use 'nikvdp/ejs-syntax'
  use 'cespare/vim-toml'
  use 'leafgarland/typescript-vim'
  use {
    'prettier/vim-prettier',
    run = 'yarn install'
  }
  use 'pangloss/vim-javascript'

  use { 'vim-jp/autofmt', ft = 'help' }

  -- Plugin Development      ==================================================

  use { 'prabirshrestha/async.vim', cmd = 'AsyncEmbed' }
  use 'lambdalisue/vital-Whisky'
  use 'vim-jp/vital.vim'
  use {
    'thinca/vim-themis',
    config = function()
      local path = packer_plugins['vim-themis'].path
      vim.env.PATH = vim.env.PATH .. ':' .. path .. '/bin'
    end,
  }

end)

-- vim: foldmethod=syntax
