#! /bin/bash -e

function get_git_info {
  # 古いtmuxのバージョンでしか pane_current_path が使用できない
  #path=`tmux display-message -p "#{pane_current_path}"`
  # 基本的にタイトルにはパス情報を設定しているので、そちらから判定する
  local current_dir=$(tmux display-message -p "#T")
  cd $current_dir
  local user_name=`git config --get user.name`
  local email_address=`git config --get user.email`
  local repo_name=`basename $(git rev-parse --show-toplevel)`
  local branch_name=`git branch | grep \*.* | sed -e 's/\*\ //'`
  local cmd=$(tmux display-message -p "#{pane_current_command}")

  local str=
  if [[ $cmd != "ssh" ]] && [[ $cmd != "sftp" ]];then
    if [[ ! -z ${repo_name} ]];then
      if [[ ${#repo_name} -gt 20 ]];then
        str+="#[fg=colour166][$(echo $repo_name | cut -c 1-17)...]"
      else
        str+="#[fg=colour166][${repo_name}]"
      fi
    fi
    if [[ ! -z ${branch_name} ]];then
      if [[ ${#branch_name} -gt 20 ]];then
        str+="#[fg=green][$(echo $branch_name | cut -c 1-17)...]"
      else
        str+="#[fg=green][${branch_name}]"
      fi
    fi
    str+="#[fg=yellow]<${user_name} | ${email_address}> "
  fi
  echo "$str"
}

echo "$(get_git_info)"
