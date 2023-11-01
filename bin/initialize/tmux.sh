#! /bin/bash -xue

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR
source ../functions

# for windows
if [[ "$(uname 2> /dev/null)" =~ MSYS ]];then
  ### pacman だと任意のバージョンが入れれず、その瞬間の最新版しか入れられず気軽にアップデート出来ないし、冪等性がない
  # pacman -Sy tmux --noconfirm
  print_info "tmux のインストールは結構手間取るので、あとで手動でインストールしてください。 tmux.sh にコメントが残っています"

  # ########################### 以下を手動で実行すること
  # # いつもの MSYS2 MSYS を起動する
  # cd ~/
  # pacman -Sy ncurses make gcc automake autoconf pkg-config libevent-devel ncurses-devel --noconfirm
  # # tmux のインストール
  # wget https://github.com/tmux/tmux/releases/download/3.3a/tmux-3.3a.tar.gz
  # tar -zxvf tmux-3.3a.tar.gz && rm tmux-3.3a.tar.gz
  # cd tmux-3.3a
  # ./configure

  # pkg-config --libs ncurses
  # pkg-config --variable=libdir ncurses
  # を確認

  # ある場合は
  # LDFLAGS="-L$(pkg-config --variable=libdir ncurses) -lncurses" ./configure

  # make
  # make install
  # # tmux が利用する一時ディレクトリのパーミッション問題が起こりがちなので、予め一時ディレクトリを変更しておく
  # # tmux.conf でも指定している
  # mkdir ~/tmux_tmp
  # chmod 700 ~/tmux_tmp

  # # おそらく以下も必要
  # pacman -S mingw-w64-x86_64-openssl --noconfirm
  # # MSYS2 MinGW 64-bit を起動する
  # # libevent のインストール
  # cd ~/
  # wget https://github.com/libevent/libevent/releases/download/release-2.1.12-stable/libevent-2.1.12-stable.tar.gz
  # tar zxf libevent-2.1.12-stable.tar.gz && rm libevent-2.1.12-stable.tar.gz
  # cd libevent-2.1.12-stable
  # export PKG_CONFIG_PATH=/mingw64/lib/pkgconfig
  # ./configure --prefix=${HOME}/local
  # make
  # make install
fi

# for ubuntu
if [[ "$(cat /etc/issue 2> /dev/null)" =~ Ubuntu ]];then
  cd /usr/local/src

  sudo apt-get -y remove tmux
  sudo apt-get install -y automake pkg-config libevent-dev libncurses5-dev xsel bison

  if [ ! -d tmux ]; then
    sudo git clone https://github.com/tmux/tmux.git
  fi

  cd tmux

  # checkout latest tag
  sudo git checkout $(git tag | grep -Ev '[a-z'] | sort -V | tail -n 1)
  sudo sh autogen.sh
  sudo ./configure && sudo make && sudo make install
fi
