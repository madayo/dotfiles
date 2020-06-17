[[ "$-" != *i* ]] && return

#################################################################### alias
alias ll='ls -la --color=auto'
alias grep='grep --color=auto'
alias less='less -N'
# 左右に並べてdiff
alias diffv='diff -ybBw -W 200 --suppress-common-lines'
# composer 関連
alias composer='composer --ansi'
alias phpfixd='php-cs-fixer --ansi fix --dry-run --diff --diff-format udiff'
alias phpfix='php-cs-fixer --ansi fix'
# ssh-agent
alias ssh-add-all='find ~/.ssh/ -maxdepth 1 -mindepth 1 -type f -name "id_*" ! -name "*.pub" | xargs ssh-add'

### tmux で複数の pane を起動している場合、少し工夫しないと多重起動が起こる
### 起動中の ssh-agent PID などをファイル出力しておき、かつその PID が現在も起動されている場合はファイルから各種設定を読み込む
### windows と Linux とで ps の挙動が異なるので注意
if [[ "$(uname 2> /dev/null)" =~ MSYS ]];then
  # alias 内の if を外出しにして、 alias 自体をシンプルにしたほうが可読性が上がるが標準出力の制御がめんどいので以下のようにした
  # 若干怪しいが概ね期待通り
  # 1. ssh-agent が複数起動している場合は一旦全て kill
  # 2. ps 一覧を確認して ssh-agent が存在する場合は、その PID がファイル出力されているか確認
  # 3. ファイル出力されている場合は、ファイルの内容を読み込む。ファイル出力されていない場合は ssh-agent を起動して、起動時の PID をファイル出力する
  alias ssh-agent-reload="if [[ $(ps aux | grep '/ssh-agent' | grep -v 'grep' | wc -l) -gt 1 ]]; then ps aux | grep '/ssh-agent' | grep -v 'grep' | awk '{print \$1}' | xargs kill; fi; if [[ -n \"\$(ps aux | grep '/ssh-agent' | grep -v 'grep' | head -n 1 | awk '{print \$1}' | xargs -I{} grep \"SSH_AGENT_PID={}\" ~/.ssh-agent-info)\" ]]; then source ~/.ssh-agent-info; else ssh-agent > ~/.ssh-agent-info; cat ~/.ssh-agent-info; fi"
fi
if [[ "$(cat /etc/issue 2> /dev/null)" =~ Ubuntu ]];then
  alias ssh-agent-reload="if [[ $(ps aux | grep 'ssh-agent' | grep -v 'grep' | wc -l) -gt 1 ]]; then ps aux | grep 'ssh-agent' | grep -v 'grep' | awk '{print \$2}' | xargs kill; fi; if [[ -n \"\$(ps aux | grep 'ssh-agent' | grep -v 'grep' | head -n 1 | awk '{print \$2}' | xargs -I{} grep \"SSH_AGENT_PID={}\" ~/.ssh-agent-info)\" ]]; then source ~/.ssh-agent-info; else ssh-agent > ~/.ssh-agent-info; cat ~/.ssh-agent-info; fi"
fi
#################################################################### tmux
# windows 環境下のみ tmux の起動法が少々特殊
# -2 オプションで強制的に端末が 256 色をサポートしていると認識させる
if [[ "$(uname 2> /dev/null)" =~ MSYS ]];then
  which tmux > /dev/null 2>&1 && alias tmux='tmux -S $(find /tmp -name "tmux*")/default -2'
# linux
else
  which tmux > /dev/null 2>&1 && alias tmux='tmux -2'
fi
#################################################################### デフォルトコマンドの拡張
# tmux起動時
if [[ -n $(printenv TMUX) ]] ; then
  . ~/dotfiles/bin/tmux/expand_functions.sh > /dev/null
  # ローカルのvmを使っている場合は背景色を変更しておく
  # TODO: これだとアクティブな pane と非アクティブな pane の色区別ができていない。改善の余地あり
  if [[ $(hostname -I 2>/dev/null | grep '192.168') ]]; then
    tmux select-pane -P 'bg=#341442' > /dev/null
  fi
fi
