#! /bin/bash -xue

# for windows
if [[ "$(uname 2> /dev/null)" =~ MSYS ]];then
  export MSYS=winsymlinks:nativestrict
  pacman -Sy git vim tree winpty --noconfirm
fi

# for ubuntu
if [[ "$(cat /etc/issue 2> /dev/null)" =~ Ubuntu ]];then
  sudo apt-get update
  sudo apt-get -y upgrade
  sudo apt-get -y dist-upgrade
fi
