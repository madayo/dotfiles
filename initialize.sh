#! /bin/bash -e

# OSの確認とインストールコマンドの振り分け
function set_install_cmd () {
  local os="`uname -s`"
  if [[ $os =~ ^CYGWIN.*$ ]]; then
    apt=apt-cyg
    # apt-cygのインストール
    cd ~
    wget https://raw.githubusercontent.com/transcode-open/apt-cyg/master/apt-cyg
    chmod 755 apt-cyg
    mv apt-cyg /usr/local/bin/
  fi
}

set_install_cmd
# 各種コマンドのインストール
$apt install tmux
$apt install vim
$apt install php
$apt install curl

# vimプラグイン管理ツール Dein.vim. NeoBundleは開発終了。その後継。
curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh -o /tmp/installer.sh
sh /tmp/installer.sh ~/.vim/dein

