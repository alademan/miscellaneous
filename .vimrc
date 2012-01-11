syntax on
set smarttab
set autoindent
set number
set mouse=a
set showmatch
set nostartofline
set tabstop=2
set shiftwidth=2
set softtabstop=2
set showtabline=1
set expandtab

set modeline
set ls=2

" Use + register (X Window clipboard) as unnamed register 
"set clipboard=unnamedplus,autoselect 


" Allow hidden buffers (i.e. allow switching buffers without requiring a write)
" set hidden

set foldenable
set foldmarker={,}
set foldmethod=indent
set foldcolumn=1
set foldlevel=100

set pastetoggle=<F2>
set pastetoggle=<Esc>p

filetype plugin indent on 

map <Esc>q :tabp<Enter>
map <Esc>e :tabn<Enter>
nnoremap <Leader>src :source ~/.vimrc<Enter>

" Unmap arrow keys
inoremap  <Up>     <NOP>
inoremap  <Down>   <NOP>
inoremap  <Left>   <NOP>
inoremap  <Right>  <NOP>
noremap   <Up>     <NOP>
noremap   <Down>   <NOP>
noremap   <Left>   <NOP>
noremap   <Right>  <NOP>

" Make them do something interesting
vmap <Left> <
vmap <Right> >
imap <Left> <C-D>
imap <Right> <C-T>
nmap <Left> <<
nmap <Right> >>

map H ^
map L $
map j gj
map k gk
map <S-j> gjgjgj
map <S-k> gkgkgk

" Replace all tabs with a double space
nnoremap <Leader>tts ggVG:s/\t/  /g<Enter>

" Allow saving of file that needs root access
cmap w!! %!sudo tee > /dev/null %

set t_Co=256
colors jellybeans

au BufWritePost,BufWinLeave,WinLeave ?* mkview
au BufWinEnter ?* silent loadview
au FileType xhtml,xml so ~/.vim/ftplugin/html_autoclosetag.vim

autocmd InsertEnter * let w:last_fdm=&foldmethod | setlocal foldmethod=manual
autocmd InsertLeave * let &l:foldmethod=w:last_fdm

set virtualedit=all

autocmd! bufwritepost 

set ofu=syntaxcomplete#Complete

let g:SuperTabDefaultCompletionType = "context"

set nocompatible

" Vimwiki stuff
let vimwiki_use_mouse = 1
nnoremap <Leader>wha :VimwikiAll2HTML<Enter>
let g:vimwiki_folding = 1
let g:vimwiki_list = [{'path': '~/vimwiki/', 'path_html': '~/vimwiki_html/', 'diary_rel_path' : ''}]
nnoremap <Leader>wgp :!~/scripts/vimwiki_git_push.sh<Enter>
nnoremap <Leader>wgl :!~/scripts/vimwiki_git_pull.sh<Enter>
let g:vimwiki_hl_headers = 1
let g:vimwiki_badsyms = ' '
let g:vimwiki_fold_lists = 1
let g:vimwiki_list_ignore_newlines = 0
nnoremap <Leader>wtq :VimwikiTableMoveColumnLeft<Enter>
nnoremap <Leader>wte :VimwikiTableMoveColumnRight<Enter>
nnoremap <Leader>wrap :set formatoptions+=l<Enter>:set lbr<Enter>
nmap <silent> <Leader>s :set spell!<Enter>
nnoremap <SPACE> za
vnoremap <SPACE> zf

" Indent Guides stuff
let g:indent_guides_start_level = 1
let g:indent_guides_guide_size = 1

" Latex
set grepprg=grep\ -nH\ $*
let g:tex_flavor = "latex"

" display wrapped lines instead of @ symbols
set display+=lastline

" gui options
set guioptions=em

" center window
let g:centerinscreen_active = 0

function! ToggleCenterInScreen(desired_width)
  if g:centerinscreen_active == 0
    let a:window_width = winwidth(winnr())
    let a:sidepanel_width = (a:window_width - a:desired_width) / 2

    exec("silent leftabove " . a:sidepanel_width . "vsplit new")
    wincmd l
    exec("silent rightbelow " . a:sidepanel_width . "vsplit new")
    wincmd h
    let g:centerinscreen_active = 1
  else
    wincmd h
    close
    wincmd l
    close

    let g:centerinscreen_active = 0
  endif
endfunction

nnoremap <Leader>r :exec ToggleCenterInScreen(100)<CR>
