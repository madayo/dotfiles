#! /bin/bash -e

source ~/dotfiles/bin/functions

# git管理下にある dotfile のみ抽出
for f in `git ls-files | sed -s 's/\/.*//g' | grep '^\.' | uniq`
do
  # リンクを貼らないものたち
  [[ $f =~ ".git" ]] && continue

  ln_dotfile ~/dotfiles/$f ~/$f
done

# リンク貼るが、ほかとディレクトリ構成が異なるものは個別に対応する
ln_dotfile ~/dotfiles/.git_global/.gitconfig ~/.gitconfig
