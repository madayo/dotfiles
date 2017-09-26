syntax enable
set background=dark
"set background=light
colorscheme solarized

""" エンコード（基本的にwindows環境を考慮していない設定。Linux環境下で問題なく動くような設定）
" 改行コード
set fileformat=unix
" 新規ファイル作成時の文字コード
set encoding=utf-8
" ファイル読み込み時の文字コード。左から順に試していく
set fileencodings=utf-8,iso-2022-jp,euc-jp,sjis
" ファイル書き込み時の文字コード。これを指定すると元ファイルの文字コードを無視して強制的に保存される。特に指定していない場合は元の値を保持する。あまり指定しない方がいい。
" :set fileencoding=utf-8
" 行番号
" 若干重くなる？必要なときだけ打ち込む
"set number

" 半角スペースインデントの設定
set tabstop=4
set autoindent
set expandtab
set shiftwidth=4

" コメント行から新たに改行した場合に自動的に#を付与する処理を無効化
" 効いていない。。。
set formatoptions-=ro

" phpのシンタックスチェック
" 有効にしたらなにやら挙動がおかしい。保存する→フォーカスが当たっている行がずれるがキャッシュ？が表示されており実際に操作している行と画面に表示される行が合わない
"augroup PHP
"	autocmd!
"	autocmd FileType php set makeprg=php\ -l\ %
"	" php -lの構文チェックでエラーがなければ「No syntax errors」の一行だけ出力される
"	autocmd BufWritePost *.php silent make | if len(getqflist()) != 1 | copen | else | cclose | endif
"augroup END


"""""""""" プラグイン
""""""" 入力補完
""""" neocomplcache
""""" https://github.com/Shougo/neocomplete.vim
""" 基本
" AutoComplPopがインストールされている場合競合するので無効化
"let g:acp_enableAtStartup = 0
" 当プラグインの自動起動
let g:neocomplcache_enable_at_startup = 1
" smartcaseの有効化。大文字が入力されるまで大文字・小文字を区別しないで補完
let g:neocomplcache_enable_smart_case = 1
" _区切りの補完の有効化
let g:neocomplcache_enable_underbar_completion = 1
" 大文字を入力した場合にワイルドカード検索してくれる。FAの場合F*A*と内部で変換される。結構処理重くなる
"let g:neocomplcache_enable_camel_case_completion = 1
" キャッシュする最低文字数。ちょっとよくわかんないのでおすすめ設定をそのまましている
let g:neocomplcache_min_syntax_length = 3
" 自動的にロックするバッファ名のパターン。ちょっとよくわかんないのでおすすめ設定をそのまましている
let g:neocomplcache_lock_buffer_name_pattern = '\*ku\*'
" 読み込み先の辞書ファイル設定。デフォルトではdictionaryを読み込んでくれるので特に拡張はしない
let g:neocomplcache_dictionary_filetype_lists = {
    \ 'default' : ''
    \ }
""" キーバインド
" Ctrl+z 直前の補完のキャンセル。補完された文字列の削除
inoremap <expr> <C-z> neocomplcache#undo_completion()
" TAB 補完候補の中から、共通する文字列部分を補完
inoremap <expr> <TAB> pumvisible() ? neocomplcache#complete_common_string() : "\<TAB>"
" Ctrl+q ポップアップのクローズ。
"inoremap <expr> <C-q> neocomplcache#smart_close_popup()
