" プラグインマネージャー --------------------------------------------------------------------------
if &compatible
  set nocompatible
endif

let g:dein_dir = expand('~/.vim/dein')
let s:dein_repo_dir = g:dein_dir . '/repos/github.com/Shougo/dein.vim' 

if !isdirectory(s:dein_repo_dir)
  execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir
endif

set runtimepath+=~/.vim/dein/repos/github.com/Shougo/dein.vim

if dein#load_state(g:dein_dir)
  " プラグインリストを収めたTOMLファイル
  let s:toml = g:dein_dir . '/dein.toml'
  "let s:lazy_toml = g:dein_dir . '/dein_lazy.toml'

  call dein#begin(expand('~/.vim/dein'), [$MYVIMRC,s:toml])

  " TOMLファイルにpluginを記述
  call dein#load_toml(s:toml, {'lazy': 0})
  "call dein#load_toml(s:lazy_toml, {'lazy': 1})

  call dein#end()
  call dein#save_state()
endif

filetype plugin indent on
syntax enable

" 未インストールのプラグインがあれば自動でインストール
if dein#check_install()
  call dein#install()
endif

" プラグイン設定 --------------------------------------------------------------------------
""""" molokai
"colorscheme darkblue
colorscheme molokai

""""" unite
" insertモードで開始する
let g:unite_enable_start_insert=1
""" キーバインド
" バッファ一覧
noremap <C-P> :Unite buffer<CR>
" ファイル一覧
noremap <C-N> :Unite -buffer-name=file file<CR>
" 最近使ったファイルの一覧
noremap <C-Z> :Unite file_mru<CR>
" ウィンドウを分割して開く
au FileType unite nnoremap <silent> <buffer> <expr> <C-J> unite#do_action('split')
au FileType unite inoremap <silent> <buffer> <expr> <C-J> unite#do_action('split')
" " ウィンドウを縦に分割して開く
au FileType unite nnoremap <silent> <buffer> <expr> <C-K> unite#do_action('vsplit')
au FileType unite inoremap <silent> <buffer> <expr> <C-K> unite#do_action('vsplit')
" ESCキーを2回押すと終了する
au FileType unite nnoremap <silent> <buffer> <ESC><ESC> :q<CR>
au FileType unite inoremap <silent> <buffer> <ESC><ESC> <ESC>:q<CR>

""""" vim-indent-guides
" 詳細よくわかっていないけど、インデント幅に指定したいスペースの数を設定すればよい
set ts=2
set sw=2
set et
" vimを立ち上げたときに、自動的にvim-indent-guidesをオンにする
let g:indent_guides_enable_on_vim_startup = 1
" ハイライトする婆
let g:indent_guides_guide_size = 2
" 自動カラー無効
let g:indent_guides_auto_colors = 0
" 奇数番目のインデントの色
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  guibg=#444433 ctermbg=gray
" 偶数番目のインデントの色
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven guibg=#333344 ctermbg=white
" ファイル別設定
augroup fileTypeIndent
  autocmd!
  autocmd BufNewFile,BufRead *.sh  setlocal ts=2 softtabstop=2 sw=2
  autocmd BufNewFile,BufRead *.py  setlocal ts=2 softtabstop=2 sw=2
  autocmd BufNewFile,BufRead *.php setlocal ts=4 softtabstop=4 sw=4
augroup END


" 基本設定 --------------------------------------------------------------------------
syntax on "コードの色分け
set expandtab "タブで挿入する文字をスペースに
set number "行番号を表示する
set title "編集中のファイル名を表示
"set cursorline "カーソルのある行にアンダーラインを引く
set showmatch "括弧入力時の対応する括弧を表示
set tabstop=4 "インデントをスペース4つ分に設定
set shiftwidth=4 "自動インデントの幅
set smartindent "オートインデント
set smarttab "新しい行を作った時に高度な自動インデント
set clipboard=unnamed,autoselect "OSのクリッポボードと連携
set matchpairs& matchpairs+=<:> "対応カッコに＜＞を追加
set backspace=eol,indent,start

" ファイル自動生成 --------------------------------------------------------------------------
set noswapfile "スワップファイルを作らない
set nobackup "バックアップを作成しない
set viminfo= "viminfoを作成しない

" 検索 --------------------------------------------------------------------------
"set ignorecase "大文字/小文字の区別なく検索する
"set smartcase "検索文字列に大文字が含まれている場合は区別して検索する
set wrapscan "検索時に最後まで行ったら最初に戻る
