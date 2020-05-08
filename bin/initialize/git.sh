#! /bin/bash -xue

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR
source ../functions

# reinstall git
if [[ "$(cat /etc/issue 2> /dev/null)" =~ Ubuntu ]];then
  sudo apt -y remove git
  # その時点での最新版を入れる
  ver=2.26.2
  wget https://github.com/git/git/archive/v${ver}.tar.gz
  tar xfz v${ver}.tar.gz
  rm v${ver}.tar.gz
  cd git-${ver}
  make configure
  ./configure --prefix=/usr
  make all doc info
  sudo make install install-doc install-html install-info
  cd ../
  rm -fr git-${ver}
  cd ${SCRIPT_DIR}
fi
# init git template dir
mkdir -p ~/.git_template/hooks
