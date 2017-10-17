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
"if dein#check_install()
"  call dein#install()
"endif

" プラグイン設定 --------------------------------------------------------------------------
" molokai
colorscheme darkblue


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
" 矢印キーを無効にする
noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>
inoremap <Up> <Nop>
inoremap <Down> <Nop>
inoremap <Left> <Nop>
inoremap <Right> <Nop>
 
" ファイル自動生成 --------------------------------------------------------------------------
set noswapfile "スワップファイルを作らない
set nobackup "バックアップを作成しない
set viminfo= "viminfoを作成しない

" 検索 --------------------------------------------------------------------------
"set ignorecase "大文字/小文字の区別なく検索する
"set smartcase "検索文字列に大文字が含まれている場合は区別して検索する
set wrapscan "検索時に最後まで行ったら最初に戻る
