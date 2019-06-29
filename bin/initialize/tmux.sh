#! /bin/bash -xue

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR
source ../functions

# for windows
if [[ "$(uname 2> /dev/null)" =~ MSYS ]];then
  pacman -Sy make autoconf automake pkg-config gcc ncurses ncurses-devel libtool bison --noconfirm
  cd ~/
  git clone https://github.com/libevent/libevent.git
  cd libevent
  sh autogen.sh && ./configure && make && make install
  cd ~/
  git clone https://github.com/tmux/tmux
  cd tmux
  # checkout latest tag
  git checkout $(git tag | sort -V | tail -n 1)
  sh autogen.sh && ./configure && make && make install
  mv tmux.exe /usr/local/bin/tmux
fi

# for ubuntu
if [[ "$(cat /etc/issue 2> /dev/null)" =~ Ubuntu ]];then
  cd /usr/local/src

  sudo apt-get -y remove tmux
  sudo apt-get install -y automake pkg-config libevent-dev libncurses5-dev xsel

  if [ ! -d tmux ]; then
    sudo git clone https://github.com/tmux/tmux.git
  fi

  cd tmux

  # checkout latest tag
  sudo git checkout $(git tag | sort -V | tail -n 1)
  sudo sh autogen.sh
  sudo ./configure && sudo make && sudo make install
fi
