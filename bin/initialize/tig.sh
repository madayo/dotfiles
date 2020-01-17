#! /bin/bash -xue

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR
source ../functions

# for windows
if [[ "$(uname 2> /dev/null)" =~ MSYS ]];then
  pacman -Sy tig --noconfirm
fi

# for ubuntu
if [[ "$(cat /etc/issue 2> /dev/null)" =~ Ubuntu ]];then
  cd ~
  git clone https://github.com/jonas/tig.git
  cd tig
  git checkout $(git tag -l | tail -n 1)

  sudo apt install -y libncurses5-dev
  make
  sudo make install prefix=/usr/local
fi
