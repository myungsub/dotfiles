" ~/.vimrc — https://github.com/myungsub/dotfiles
" Works in vim, neovim and vim.tiny (Ubuntu's `vi`). vim.tiny has no +eval,
" so it skips everything inside the `if 1` block.
set nocompatible
set backspace=indent,eol,start

if 1
    set background=dark
    silent! colorscheme delek
    syntax on
    filetype on

    " System clipboard when this build has one (unnamedplus in neovim)
    if has('clipboard')
        let &clipboard = has('nvim') ? 'unnamedplus' : 'unnamed'
    endif

    set number ruler showcmd showmode title laststatus=2
    set tabstop=4 shiftwidth=4 expandtab
    set hlsearch incsearch ignorecase gdefault
    set wildmenu mouse=a scrolloff=3 nostartofline shortmess=atI noerrorbells
    set encoding=utf-8 nobomb
    set modeline modelines=4
    if exists('+fixendofline')
        set nofixendofline
    endif

    " ,ss strips trailing whitespace without moving the view or the last search
    let mapleader = ","
    function! StripWhitespace()
        let l:view = winsaveview()
        keeppatterns %s/\s\+$//e
        call winrestview(l:view)
    endfunction
    noremap <leader>ss :call StripWhitespace()<CR>
endif
