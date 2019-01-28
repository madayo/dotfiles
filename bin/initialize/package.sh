#! /bin/bash -xue

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR
source ../functions

# for windows
if [[ "$(uname 2> /dev/null)" =~ MSYS ]];then
  export MSYS=winsymlinks:nativestrict
  pacman -Sy vim winpty gcc make --noconfirm
  ln -s /usr/bin/vim /usr/bin/vi
  wget https://osdn.jp/projects/nkf/downloads/64158/nkf-2.1.4.tar.gz
  tar zxvf nkf-2.1.4.tar.gz
  cd nkf-2.1.4
  make && make install
  rm nkf-2.1.4.tar.gz && rm -fr nkf-2.1.4
fi

# for ubuntu
if [[ "$(cat /etc/issue 2> /dev/null)" =~ Ubuntu ]];then
  # dein not support vim 7.4. need to use vim 8.0.
  sudo add-apt-repository ppa:jonathonf/vim
  sudo apt-get update
  sudo apt install vim
  sudo apt-get -y upgrade
  sudo apt-get -y dist-upgrade
fi
