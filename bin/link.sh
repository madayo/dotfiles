#! /bin/bash -e

cd $(dirname $0)

source functions

cd ../
# git管理下にある dotfile のみ抽出
for f in `git ls-files | sed -s 's@/.*@@g' | grep '^\.' | uniq`; do
  ln_dotfile ~/dotfiles/$f ~/$f
done

# リンク貼るが、ほかとディレクトリ構成が異なるものは個別に対応する
ln_dotfile ~/dotfiles/.git_global/.gitconfig ~/.gitconfig

source ~/.bash_profile
