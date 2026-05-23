" ----------------------------------------------------
" package management (vim-plug)
" ----------------------------------------------------
call plug#begin('~/.vim/plugged')
" common ui/edit
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-commentary'
Plug 'airblade/vim-gitgutter'
Plug 'vim-airline/vim-airline'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'editorconfig/editorconfig-vim'

" filer
Plug 'preservim/nerdtree'

" quick run
Plug 'thinca/vim-quickrun'

" lsp/auto complete
Plug 'neoclide/coc.nvim', { 'branch': 'release' }

" ide for programming
Plug 'fatih/vim-go', { 'for': 'go' }
Plug 'rust-lang/rust.vim', { 'for': 'rust' }
Plug 'leafgarland/typescript-vim', { 'for': ['typescript', 'typescriptreact'] }
Plug 'maxmellon/vim-jsx-pretty',   { 'for': ['javascriptreact', 'typescriptreact'] }
Plug 'pangloss/vim-javascript',    { 'for': ['javascript', 'javascriptreact'] }
Plug 'prettier/vim-prettier', {
  \ 'do': 'yarn install --frozen-lockfile --production',
  \ 'for': ['javascript', 'typescript', 'css', 'less', 'scss', 'json', 'graphql', 'markdown', 'vue', 'svelte', 'yaml', 'html'] }
call plug#end()

" key mapping
let g:mapleader = ","

set fillchars+=stl:─,stlnc:─,vert:│
" extensions for coc.nvim
let g:coc_global_extensions = [
  \ 'coc-css',
  \ 'coc-go',
  \ 'coc-html',
  \ 'coc-java',
  \ 'coc-json',
  \ 'coc-prettier', 
  \ 'coc-pyright',
  \ 'coc-tsserver',
  \ 'coc-yaml',
  \ ]
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
  \ : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" color
syntax on
set termguicolors
set bg=dark
"set bg=light

" fold
set nofoldenable

" encoding
set enc=utf-8
set fenc=utf-8
set fencs=ucs-bom,utf-8,iso-2022-jp,cp932,euc-jp,sjis,utf-16,utf-16le
set fileformats=unix,dos,mac

" search
set ignorecase
set smartcase
set noincsearch

" basic indent
set backspace=indent,eol,start
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
set smartindent
set autoindent
"set paste

" language specific indent
autocmd BufNewFile,BufRead *.avsc set filetype=json
autocmd FileType java setlocal tabstop=2
autocmd FileType cpp setlocal tabstop=4
autocmd FileType javascript,ruby,yaml,xml,html,json,proto setlocal shiftwidth=2 softtabstop=2
autocmd FileType python setlocal tabstop=8

" translating diff work
autocmd FileType rst nnoremap ,d :1,$d<Cr>

" other
set showmatch
set title
"set number
set ruler

" cursor
nnoremap L 10l
nnoremap H 10h

" buffer
set hidden

" check width more than 80
set textwidth=0
if exists('&colorcolumn')
    set colorcolumn=+1
    autocmd FileType sh,js,ts,cpp,perl,vim,md,rst,python,ruby,go setlocal textwidth=80
endif

" actionscript syntax highlight
autocmd BufNewFile,BufRead *.as set filetype=actionscript

" share clipboard
if has("unnamedplus")
    set clipboard=unnamedplus  " X11 support
else
    set clipboard=unnamed
endif

" adjust lines in quickfix window
autocmd FileType qf call AdjustWindowHeight(3, 7)
function! AdjustWindowHeight(minheight, maxheight)
  exe max([min([line("$"), a:maxheight]), a:minheight]) . "wincmd _"
endfunction

" ----------------------------------------------------
" quick run
" ----------------------------------------------------
let g:quickrun_config = {
    \ '_': {
    \   'runner'                          : 'job',
    \   'runner/job/interval'             : 100,
    \   'outputter'                       : 'buffer',
    \   'outputter/buffer/opener'         : 'botright 3split',
    \   'outputter/buffer/close_on_empty' : 1,
    \ },
    \ }
nnoremap <expr><silent> <C-c> quickrun#is_running() ? quickrun#sweep_sessions() : "\<C-c>"
augroup QuickRunOutput
  autocmd!
  autocmd FileType quickrun nnoremap <buffer> q :quit<CR>
augroup END
autocmd FileType ruby nnoremap fj :QuickRun ruby <Cr>
autocmd FileType python nnoremap fj :QuickRun python3 <Cr>
autocmd FileType rust nnoremap fj :QuickRun rustc <Cr>
autocmd FileType sh nnoremap fj :QuickRun bash <Cr>
autocmd FileType go nnoremap fj :QuickRun go -args run <Cr>

" ----------------------------------------------------
" vim-go
" ----------------------------------------------------
let g:go_bin_path = expand("$HOME/go/bin")
let g:go_fmt_command = "goimports"
let g:go_rename_command = "gopls"
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_types = 1
let g:go_metalinter_command = "golangci-lint"
let g:go_metalinter_autosave = 0
let g:go_metalinter_autosave_enabled = ['vet']
let g:go_addtags_transform = "camelcase"
let g:go_echo_command_info = 0
let g:go_build_tags = "integration"
set completeopt=menuone,noinsert,noselect
nnoremap <Leader>a :cclose<CR>
autocmd FileType go nmap <Leader>r <Plug>(go-run)
autocmd FileType go nmap <Leader>b <Plug>(go-build)
autocmd FileType go nmap <Leader>t <Plug>(go-test)
autocmd FileType go nmap <Leader>c <Plug>(go-coverage)
autocmd FileType go nmap <Leader>ds <Plug>(go-def-split)
autocmd FileType go nmap <Leader>dv <Plug>(go-def-vertical)
autocmd FileType go nmap <Leader>dt <Plug>(go-def-tab)
autocmd FileType go nmap <Leader>gd <Plug>(go-doc)
autocmd FileType go nmap <Leader>gv <Plug>(go-doc-vertical)
autocmd FileType go nmap <Leader>gb <Plug>(go-doc-browser)
autocmd FileType go nmap <Leader>s <Plug>(go-implements)
autocmd FileType go nmap <Leader>i <Plug>(go-info)
autocmd FileType go nmap <Leader>e <Plug>(go-rename)
autocmd FileType go nmap <Leader>rf <Plug>(go-referrers)
