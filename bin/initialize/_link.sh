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
make_symbolic_links ~/dotfiles/AGENTS.md ~/CLAUDE.md
make_symbolic_links ~/dotfiles/claude/CLAUDE.md ~/.claude/CLAUDE.md
make_symbolic_links ~/dotfiles/claude/settings.json ~/.claude/settings.json
make_symbolic_links ~/dotfiles/claude/commands ~/.claude/commands
make_symbolic_links ~/dotfiles/codex/hooks.json ~/.codex/hooks.json

# ~/.codex/skills には Codex 管理の system skills も配置されるため、
# ディレクトリごと置換せず、dotfiles 管理したい個別 skill だけをリンクする。
mkdir -p ~/.codex/skills
make_symbolic_links ~/dotfiles/codex/skills/my-pr ~/.codex/skills/my-pr
make_symbolic_links ~/dotfiles/codex/skills/my-review ~/.codex/skills/my-review
make_symbolic_links ~/dotfiles/codex/skills/my-copilot-review ~/.codex/skills/my-copilot-review
make_symbolic_links ~/dotfiles/codex/skills/my-handoff ~/.codex/skills/my-handoff

print_info "codex の config.toml はシンボリックリンクにせず、必要な部分のテキストを手動でコピペしてください。"

mkdir -p ~/.vscode-server/data/User
make_symbolic_links ~/dotfiles/.copilot/prompts ~/.vscode-server/data/User/prompts

print_info "windows 側の User ディレクトリの Music フォルダに beep-claude.wav を設置してください。Claude の通知音に使用します。"
print_info "windows 側の User ディレクトリの Music フォルダに beep-copilot.wav を設置してください。Copilot の通知音に使用します。"

# コピーのほうが高速なのでコピー
WIN_USER=$(get_windows_username)
cp "$SCRIPT_DIR/../../image/bg1.jpg" "/mnt/c/Users/$WIN_USER/Pictures/bg1.jpg"
