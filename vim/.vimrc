"General settings
colorscheme slate
set number          " Display line numbers
syntax on           " Enable syntax highlighting
set tabstop=4       " Number of spaces that a <Tab> in the file counts for
set autoindent      " Copy indent from current line when starting a new line
set expandtab       " Convert tabs to spaces
set shiftwidth=4    " Number of spaces to use for each step of (auto)indent
set ignorecase      " Ignore case when searching
set smartcase       " Override ignorecase if search pattern has uppercase letters
set incsearch       " Show search matches as you type
set hlsearch        " Highlight search matches
set mouse=a         " Enable mouse support in all modes
set clipboard=unnamedplus  " Use the system clipboard for all yank, delete, change and put operations
set showmatch       " Highlight matching [{()}]
set list            " Show non-printable characters like tabs and trailing spaces
set listchars=tab:>-,trail:·  " Set characters to represent tabs and trailing spaces
set foldmethod=indent   " Enable folding based on indent level
set foldnestmax=10      " Set maximum fold depth
set nofoldenable        " Don't fold by default
set laststatus=2    " Always display the status line

" Plugin initialization
call plug#begin()   " Initialize the plug plugin manager
Plug 'neoclide/coc.nvim', {'branch': 'release'}  " Install coc.nvim plugin from the release branch
call plug#end()     " Finalize the plug plugin manager setup

" Key mappings
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
" In insert mode, remap <CR> (Enter key) to confirm the completion if the completion menu is visible.
" Otherwise, <C-g>u breaks undo, <CR> starts a new line, and <c-r>=coc#on_enter()\<CR> handles on-enter event.


