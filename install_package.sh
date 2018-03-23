#! /bin/bash -xue

# for windows
if [[ "$(uname 2> /dev/null)" =~ MSYS ]];then
  export MSYS=winsymlinks:nativestrict
  pacman -Sy vim --noconfirm
  ln -s /usr/bin/vim /usr/bin/vi
fi

# for ubuntu
if [[ "$(cat /etc/issue 2> /dev/null)" =~ Ubuntu ]];then
  sudo apt-get update
  sudo apt-get -y upgrade
  sudo apt-get -y dist-upgrade
fi
