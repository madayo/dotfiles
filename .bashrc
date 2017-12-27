[[ "$-" != *i* ]] && return

#################################################################### alias
alias ll='ls -la --color=auto'
alias grep='grep --color=auto'
alias less='less -N'
alias color='curl -L http://bit.ly/WcP1DB | /bin/bash'
# 左右に並べてdiff
alias diffv='diff --side-by-side --suppress-common-lines'
# composer 関連
alias composer='composer --ansi'
alias phpunit='phpunit --color=always'
#################################################################### tmux
# 初回シェル時のみ tmux実行
if [ ${SHLVL} = 1 ]; then
  which tmux > /dev/null 2>&1 && tmux -2
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
    ssh-add
fi
#################################################################### デフォルトコマンドの拡張
function ssh() {
  # tmux起動時
  if [[ -n $(printenv TMUX) ]] ; then
    # 現在のペインIDの退避と背景色の書き換え
    local pane_id=`sh ~/dotfiles/bin/tmux/change_color_on_tmux_current_pane.sh $@`
    # 通常通りコマンド続行
    command ssh $@
    # デフォルトの色設定に戻す
    tmux select-pane -t $pane_id -P 'default'
  else
    command ssh $@
  fi
}
function sftp() {
  # tmux起動時
  if [[ -n $(printenv TMUX) ]] ; then
    # 現在のペインIDの退避と背景色の書き換え
    local pane_id=`sh ~/dotfiles/bin/tmux/change_color_on_tmux_current_pane.sh $@`
    # 通常通りコマンド続行
    command sftp $@
    # デフォルトの色設定に戻す
    tmux select-pane -t $pane_id -P 'default'
  else
    command sftp $@
  fi
}

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
