[[ "$-" != *i* ]] && return

#################################################################### alias
alias ll='ls -la --color=auto'
alias grep='grep --color=auto'
alias less='less -N'
# 左右に並べてdiff
alias diffv='diff -ybBw --side-by-side --suppress-common-lines'
# composer 関連
alias composer='composer --ansi'
alias phpfixd='php-cs-fixer --ansi fix --dry-run --diff --diff-format udiff'
alias phpfix='php-cs-fixer --ansi fix'
#################################################################### tmux
# 初回シェル時のみ tmux実行.
if [[ ${SHLVL} = 1 ]]; then
  # windows
  if [[ "$(uname 2> /dev/null)" =~ MSYS ]];then
    which tmux > /dev/null 2>&1 && tmux -S $(find /tmp -name "tmux*")/default -2 && alias tmux='tmux -S $(find /tmp -name "tmux*")/default -2'
  # linux
  else
    which tmux > /dev/null 2>&1 && tmux -2
  fi
fi
#################################################################### ssh-agent
echo -n "ssh-agent: "
source ~/.ssh-agent-info
# ssh-agentと通信ができない場合は再起動
ssh-add -l >&/dev/null
if [ $? == 2 ] ; then
  echo -n "ssh-agent: restart...."
  ssh-agent >~/.ssh-agent-info
  source ~/.ssh-agent-info
fi
# 登録済みのキーが存在しない場合はssh-add実行
if ssh-add -l >&/dev/null ; then
  echo "ssh-agent: Identity is already stored."
else
  # 拡張子なしのファイルはすべて鍵ファイルとみなす
  ls ~/.ssh/ | grep -vE 'config$|known_hosts$|\.' | xargs -I{} ssh-add ~/.ssh/{}
fi
#################################################################### デフォルトコマンドの拡張
# tmux起動時
if [[ -n $(printenv TMUX) ]] ; then
  . ~/dotfiles/bin/tmux/expand_functions.sh
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
