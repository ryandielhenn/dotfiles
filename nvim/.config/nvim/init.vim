" =========================
" Core settings
" =========================
set number
set tabstop=4 softtabstop=4 shiftwidth=4 expandtab
set hidden
set encoding=utf-8
set nobackup nowritebackup
set updatetime=300
set shortmess+=c
set signcolumn=yes
set report=0

let mapleader=" "
let g:editorconfig = v:false

" =========================
" Plugins (vim-plug)
" =========================
call plug#begin('~/.vim/plugged')
  Plug 'sainnhe/everforest'
  Plug 'ojroques/nvim-osc52'
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'vim-airline/vim-airline'
  Plug 'vim-airline/vim-airline-themes'
  Plug 'edkolev/tmuxline.vim'
  Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && npm install' }
  Plug 'tpope/vim-fugitive'
  Plug 'airblade/vim-gitgutter'
  Plug 'skywind3000/asyncrun.vim'
  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
  Plug 'tpope/vim-vinegar'
call plug#end()

" =========================
" Theme & UI
" =========================
colorscheme everforest
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline_theme = 'everforest'
let g:airline_section_c = '%{coc#status()}'

" =========================
" Clipboard: OSC52 (SSH-safe) with local fallbacks
" =========================
lua << EOF
local ok, osc52 = pcall(require, 'osc52')
if not ok then return end

-- Store last yank so paste() never calls @+ recursively
local last = { lines = nil, regtype = 'v' }

local function copy(lines, regtype)
  last.lines = vim.deepcopy(lines)
  last.regtype = regtype or 'v'
  osc52.copy(table.concat(lines, '\n'))
end

local function paste()
  if last.lines then
    return last.lines, last.regtype
  end
  local s = vim.fn.getreg('"')
  return vim.split(s, '\n', { plain = true, trimempty = false }), vim.fn.getregtype('"')
end

vim.g.clipboard = {
  name  = 'osc52',
  copy  = { ['+'] = copy, ['*'] = copy },
  paste = { ['+'] = paste, ['*'] = paste },
}

vim.opt.clipboard = 'unnamedplus'
EOF

" =========================
" Yank highlight (Catppuccin-aware)
" =========================
if exists('g:colors_name') && g:colors_name =~ 'catppuccin'
  highlight YankHighlight guibg=#b4befe guifg=NONE gui=bold
else
  highlight YankHighlight guibg=#444444 guifg=#ffffff gui=bold
endif
augroup highlight_yank
  autocmd!
  autocmd TextYankPost * silent! lua vim.highlight.on_yank({ higroup="YankHighlight", timeout=150 })
augroup END

" =========================
" File navigation (NERDTree-free)
" =========================
let g:netrw_banner=0
let g:netrw_liststyle=3
let g:netrw_browse_split=0
let g:netrw_winsize=25
" Quick file/browser mappings
nnoremap <silent> <leader>ff :Files<CR>
nnoremap <silent> <leader>fg :Rg<Space>
nnoremap <silent> <leader>fb :Buffers<CR>
nnoremap <silent> <leader>fe :Lexplore<CR>
nnoremap <silent> gf :GFiles<CR>

" =========================
" FZF ripgrep helper
" =========================
let g:fzf_layout = { 'down': '40%' }
command! -bang -nargs=* Rg call fzf#vim#grep(
      \ 'rg --column --line-number --no-heading --color=always '.<q-args>, 1,
      \ <bang>0 ? fzf#vim#with_preview('up:60%')
      \         : fzf#vim#with_preview('right:50%:hidden', '?'),
      \ <bang>0)

" =========================
" CoC minimal sane mappings
" =========================
inoremap <silent><expr> <TAB>   coc#pum#visible() ? coc#pum#next(1)  : CheckBackspace() ? "\<Tab>" : coc#refresh()
inoremap <expr>        <S-TAB>  coc#pum#visible() ? coc#pum#prev(1)  : "\<C-h>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1] =~# '\s'
endfunction

inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
      \ : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
inoremap <silent><expr> <C-Space> coc#refresh()

nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

nnoremap <silent> K :call CocAction('doHover')<CR>
nmap <leader>rn <Plug>(coc-rename)
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

" =========================
" Treesitter (syntax & indent)
" =========================
lua << EOF
pcall(function()
  require('nvim-treesitter.configs').setup({
    highlight = { enable = true },
    indent    = { enable = true },
  })
end)
EOF

" =========================
" Git + AsyncRun + misc
" =========================
nnoremap <silent> gb :Git blame<CR>
let g:asyncrun_open = 10
nnoremap <silent> <leader>ar :AsyncRun<Space>
nnoremap <silent> bn :bn<CR>
nnoremap <silent> bp :bp<CR>
