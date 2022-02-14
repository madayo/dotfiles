#! /bin/bash -xue

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR
source ../functions

# for windows
if [[ "$(uname 2> /dev/null)" =~ MSYS ]];then
  # windows 向けのインストーラを使用して、手動でインストールする
  print_info 'node が必要な場合は volta https://docs.volta.sh/guide/getting-started を手動でインストールしてください。'
fi

# for ubuntu
if [[ "$(cat /etc/issue 2> /dev/null)" =~ Ubuntu ]];then
  curl https://get.volta.sh | bash
  exec $SHELL -l
fi
