#! /bin/bash -xue

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR
source ../functions

# for windows
if [[ "$(uname 2> /dev/null)" =~ MSYS ]];then
  # windows 向けのインストーラを使用して、手動でインストールする
  print_info 'node が必要な場合は https://github.com/coreybutler/nvm-windows を使用して手動でインストールしてください。'
  print_info 'インストール先、シンボリックリンク先は自由に設定してください。もしパス周りが解決できず、 node --verison の様に使用できない場合は環境変数をいじってください。'
  print_info 'export PATH=/d/node/nodejs:$PATH  など・・・'
fi

# for ubuntu
if [[ "$(cat /etc/issue 2> /dev/null)" =~ Ubuntu ]];then
  apt install -y nodejs npm
  npm install n -g
  n stable
  apt purge -y nodejs npm
  exec $SHELL -l
fi
