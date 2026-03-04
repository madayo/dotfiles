#! /bin/bash -xue

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../functions"

make_symbolic_links ~/dotfiles/.bashrc ~/.bashrc
make_symbolic_links ~/dotfiles/.vim ~/.vim
make_symbolic_links ~/dotfiles/.vimrc ~/.vimrc

# リンク貼るが、ほかとディレクトリ構成が異なるものは個別に対応する
make_symbolic_links ~/dotfiles/.git_global/.gitconfig ~/.gitconfig
make_symbolic_links ~/dotfiles/.ssh_config ~/.ssh/config
