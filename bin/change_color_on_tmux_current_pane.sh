#!/bin/sh -e

# 現在のペインIDを退避
pane_id=`tmux display -p '#{pane_id}'`
# 接続先ホスト名に応じて背景色、文字色を切り替え
if [[ `echo $1 | grep '\.production\.'` ]] ; then
    tmux select-pane -P 'bg=colour52,fg=white'
elif [[ `echo $1 | grep '\.staging\.'` ]] ; then
    tmux select-pane -P 'bg=colour58,fg=white'
elif [[ `echo $1 | grep '\.dev\.'` ]] ; then
    tmux select-pane -P 'bg=colour28,fg=white'
fi

echo $pane_id
