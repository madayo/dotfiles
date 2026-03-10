#! /bin/bash -e

function ssh() {
  # 引数を2つ渡している場合は、接続先で実行したいコマンドも渡している。その場合はタイトルや背景色を変えない
  # コマンド流して別ウィンドウで作業することがほとんどなので、その場合 select-pane で操作中のペインが切り替えられてしまい使い勝手が悪い
  if [ $# -gt 1 ]; then
    command ssh $@
  else
    # 現在のペインIDの退避と背景色の書き換え
    local pane_id=`bash ~/dotfiles/bin/tmux/change_color_on_tmux_current_pane.sh $1`
    tmux select-pane -t "${pane_id}" -T "${1}"

    command ssh $@

    # デフォルトの色設定に戻す
    tmux select-pane -t ${pane_id} -P 'default' && tmux select-pane -t ${pane_id} -T "$(pwd)"
  fi
}

function sftp() {
  # 現在のペインIDの退避と背景色の書き換え
  local pane_id=`bash ~/dotfiles/bin/tmux/change_color_on_tmux_current_pane.sh $1`

  command sftp $@

  # デフォルトの色設定に戻す
  tmux select-pane -t ${pane_id} -P 'default' && tmux select-pane -t ${pane_id} -T "$(pwd)"
}

