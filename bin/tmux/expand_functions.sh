#! /bin/bash -e

function ssh() {
  # 現在のペインIDの退避と背景色の書き換え
  local pane_id=`sh ~/dotfiles/bin/tmux/change_color_on_tmux_current_pane.sh $@`
  tmux select-pane -T "${!#}"

  command ssh $@

  # デフォルトの色設定に戻す
  tmux select-pane -t $pane_id -P 'default'
}

function sftp() {
  # 現在のペインIDの退避と背景色の書き換え
  local pane_id=`sh ~/dotfiles/bin/tmux/change_color_on_tmux_current_pane.sh $@`

  command sftp $@

  # デフォルトの色設定に戻す
  tmux select-pane -t $pane_id -P 'default'
}

function prompt {
  # 毎回コマンド終了後に、paneのタイトルをカレントディレクトリにする
  tmux select-pane -T "$(pwd)"
}
PROMPT_COMMAND=prompt
