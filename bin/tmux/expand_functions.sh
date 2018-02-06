#! /bin/bash -e

function cd() {
  command cd $@
  tmux select-pane -T "$(pwd)"
}

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
