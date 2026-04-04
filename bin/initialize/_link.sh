#! /bin/bash -xue

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../functions"

make_symbolic_links ~/dotfiles/.bashrc ~/.bashrc
make_symbolic_links ~/dotfiles/.vim ~/.vim
make_symbolic_links ~/dotfiles/.vimrc ~/.vimrc
make_symbolic_links ~/dotfiles/.poshthemes ~/.poshthemes
make_symbolic_links ~/dotfiles/.tmux.conf ~/.tmux.conf

# リンク貼るが、ほかとディレクトリ構成が異なるものは個別に対応する
make_symbolic_links ~/dotfiles/.git_global/.gitconfig ~/.gitconfig
make_symbolic_links ~/dotfiles/.ssh_config ~/.ssh/config
make_symbolic_links ~/dotfiles/.claude/CLAUDE.md ~/.claude/CLAUDE.md

# コピーのほうが高速なのでコピー
WIN_USER=$(get_windows_username)
cp "$SCRIPT_DIR/../../image/bg1.jpg" "/mnt/c/Users/$WIN_USER/Pictures/bg1.jpg"
