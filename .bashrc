[[ "$-" != *i* ]] && return

# ==================== Basic ====================
export EDITOR=vim
export LANG=ja_JP.UTF-8

echo -ne '\e[5 q'

# 履歴
HISTSIZE=5000
HISTFILESIZE=10000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend

# ターミナルのサイズ変更を検知して、行数と列数を自動で更新する
shopt -s checkwinsize
# less でバイナリファイル見る場合
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
# ls の色付け
if [ -x /usr/bin/dircolors ]; then
  eval "$(dircolors -b)"
  alias ls='ls --color=auto'
fi

# fzf (key bindings / completion)
[ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && source /usr/share/doc/fzf/examples/key-bindings.bash
[ -f /usr/share/doc/fzf/examples/completion.bash ] && source /usr/share/doc/fzf/examples/completion.bash

# ssh-agent のソケットパスを環境変数に設定
export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR%/}/ssh-agent.socket"

# ==================== alias ====================
# ssh-agent に鍵を追加するエイリアス
alias addkeys='for key in ~/.ssh/*; do [[ -f "$key" && ! "$key" =~ \.pub$ ]] && grep -q "PRIVATE KEY" "$key" 2>/dev/null && ssh-add "$key" 2>/dev/null; done; ssh-add -l'

alias ll='ls -lah'
alias la='ls -A'
alias grep='grep --color=auto'
alias less='less -N'
# 左右に並べてdiff
alias diffv='diff -ybBw -W 200 --suppress-common-lines'
# docker コマンドの色付け
# スペース入の alias 名はだめだった
alias dockercompose="docker compose --ansi=always"

# ==================== function ====================
# git branch表示をプロンプトに入れる
parse_git_branch() {
  git branch 2>/dev/null | sed -n '/\* /s///p' | sed 's/^/ /'
}
# docker コンテナへログイン
dlogin() {
  if [ -z "$1" ]; then
    echo "Usage: login <container_name>"
    return 1
  fi
  docker compose exec "$1" bash
}
beep() {
  ffplay -nodisp -autoexit -loglevel quiet "$HOME/dotfiles/sound/beep.mp3" >/dev/null 2>&1 &
}
ssh() {
    host="$1"

    if [[ "$host" == *.dev.* ]]; then
        PS1_STR='\[\e[30;42m\][DEV]\[\e[0m\] \u@\h:\w\$ '
    elif [[ "$host" == *.production.* ]]; then
        PS1_STR='\[\e[97;41m\][PROD]\[\e[0m\] \u@\h:\w\$ '
    else
        PS1_STR='\[\e[97;44m\][SSH]\[\e[0m\] \u@\h:\w\$ '
    fi

    command ssh "$host" -t "bash --rcfile <(cat ~/.bashrc; echo 'PS1=\"$PS1_STR\"') -i"
}

# ==================== Prompt ====================
PS1='\[\e[36m\]\u@\h\[\e[0m\]:\[\e[33m\]\W\[\e[0m\]\[\e[35m\]$(parse_git_branch)\[\e[0m\] $ '
#  msys2 時代に使っていたもの
# PS1="\[\e[01;32m\][\u@\H]\[\e[01;34m\]\[\e[00m\]:\[\e[01;35m\]\W\[\e[01;34m\] \$ \e[01;00m\]"


# ===== WSL detection =====
# $IS_WSL で WSL かどうかを判定できるようにする
if [ -n "$WSL_DISTRO_NAME" ]; then
  IS_WSL=1
fi

# ===== Windows PATH整理（WSL特有）=====
if [ "$IS_WSL" = "1" ]; then
  # Windows側PATHが長すぎる場合に整理
  export PATH=$(echo "$PATH" | tr ':' '\n' | awk '!seen[$0]++' | paste -sd:)
fi

# ===== Volta =====
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# ===== oh-my-posh =====
export PATH="$HOME/.local/bin:$PATH"
# eval "$(oh-my-posh init bash --config $HOME/.poshthemes/onehalf.minimal.omp.json)"
eval "$(oh-my-posh init bash --config $HOME/.poshthemes/my-theme.omp.json)"

# 入力補完
if [ -f /usr/share/bash-completion/completions/ssh ]; then
  source /usr/share/bash-completion/completions/ssh
fi
