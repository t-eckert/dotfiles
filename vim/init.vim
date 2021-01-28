set exrc
set relativenumber
set nohlsearch
set hidden
set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab
set smartindent
set autoindent
set nu
set smartcase
set noswapfile
set nobackup
set undodir=~/.vim/undodir
set undofile
set incsearch
set scrolloff=8
set noshowmode
set completeopt=menuone,noinsert,noselect
set signcolumn=yes
set number
set linebreak
set showmatch
set visualbell
set hlsearch
set smartcase
set ignorecase
set smarttab
set ruler
set undolevels=1000
set backspace=indent,eol,start


call plug#begin('{{ $path-to-plugged }}')

Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'gilgigilgil/anderson.vim'

call plug#end()

let g:coc_global_extensions = [
  \ 'coc-snippets',
  \ 'coc-pairs',
  \ 'coc-vetur',
  \ 'coc-omnisharp',
  \ 'coc-tsserver',
  \ 'coc-eslint', 
  \ 'coc-prettier', 
  \ 'coc-json', 
  \ ]

colorscheme anderson

nnoremap <C-J> <C-W>j
nnoremap <C-K> <C-W>k
nnoremap <C-L> <C-W>l
nnoremap <C-H> <C-W>h

let mapleader = " "
