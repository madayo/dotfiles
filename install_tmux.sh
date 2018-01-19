#! /bin/bash -xue

# for windows
if [[ "$(uname 2> /dev/null)" =~ MSYS ]];then
  pacman -Sy make autoconf pkg-config automake-wrapper gcc mingw-w64-x86_64-ncurses ncurses-devel libtool --noconfirm
  cd ~/
  git clone https://github.com/libevent/libevent.git
  cd libevent
  sh autogen.sh
  ./configure
  make
  make install
  cd ~/
  git clone https://github.com/tmux/tmux
  cd tmux
  sh autogen.sh
  ./configure
  make
  make install
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
  sudo ./configure && sudo make

  sudo cp ./tmux /usr/local/bin
fi
