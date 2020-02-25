#! /bin/bash -xue

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR
source ../functions

# for windows
if [[ "$(uname 2> /dev/null)" =~ MSYS ]];then
  sed -i -e 's/^#Color$/Color/g' /etc/pacman.conf
  pacman -Sy vim winpty gcc make --noconfirm
  ln -s /usr/bin/vim /usr/bin/vi
  wget --no-check-certificate https://osdn.net/projects/nkf/downloads/70406/nkf-2.1.5.tar.gz
  tar zxvf nkf-2.1.5.tar.gz
  cd nkf-2.1.5
  make && make install
  cd ../
  rm nkf-2.1.5.tar.gz && rm -fr nkf-2.1.5
fi

# for ubuntu
if [[ "$(cat /etc/issue 2> /dev/null)" =~ Ubuntu ]];then
  # dein not support vim 7.4. need to use vim 8.0.
  sudo add-apt-repository ppa:jonathonf/vim
  sudo apt-get update
  sudo apt -y install vim
  sudo apt -y install libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev autoconf asciidoc xmlto docbook2x make gcc
  sudo apt-get -y upgrade
  sudo apt-get -y dist-upgrade
fi
