#! /bin/bash -e

function get_git_info {
  # 古いtmuxのバージョンでしか pane_current_path が使用できない
  #path=`tmux display-message -p "#{pane_current_path}"`
  # 基本的にタイトルにはパス情報を設定しているので、そちらから判定する
  # 時々現在実行中のコマンド内容がタイトルに設定されてしまうケースがあるので、有効なパスであるか判定する
  local current_dir=$(tmux display-message -p "#T")
  if [[ ! -d "$current_dir" ]];then
    echo ""
  fi
  cd $current_dir
  local user_name=`git config --get user.name`
  local email_address=`git config --get user.email`
  local branch_name=`git branch | grep \*.* | sed -e 's/\*\ //'`
  local cmd=$(tmux display-message -p "#{pane_current_command}")

  local str=
  if [[ $cmd != "ssh" ]] && [[ $cmd != "sftp" ]];then
    if [[ ! -z ${branch_name} ]];then
      str+="#[fg=green][${branch_name}]"
    fi
    str+="#[fg=yellow]<${user_name} | ${email_address}> "
  fi
  echo "$str"
}

echo "$(get_git_info)"
