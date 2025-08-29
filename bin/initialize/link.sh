#! /bin/bash -xue

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR
source ../functions

cd ../../
# git管理下にある dotfile のみ抽出
for f in `git ls-files | sed -s 's@/.*@@g' | grep '^\.' | uniq`; do
  make_symbolic_links ~/dotfiles/$f ~/$f
done

# リンク貼るが、ほかとディレクトリ構成が異なるものは個別に対応する
make_symbolic_links ~/dotfiles/.git_global/.gitconfig ~/.gitconfig
make_symbolic_links ~/dotfiles/.ssh_config $(cygpath $HOMEDRIVE$HOMEPATH/.ssh/config)

# for windows
if [[ "$(uname 2> /dev/null)" =~ MSYS ]];then
  mkdir -p $(cygpath $HOMEDRIVE$HOMEPATH/.ssh) && make_symbolic_links $(cygpath $HOMEDRIVE$HOMEPATH/.ssh) ~/.ssh
  # composer は不要。書き分けが面倒なので一度貼ったリンクを削除する形で対応
  rm -fr ~/.composer
fi

source ~/.bash_profile
