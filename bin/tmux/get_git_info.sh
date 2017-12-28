#! /bin/bash -e

function get_git_info {
  cd `tmux display-message -p -F "#{pane_current_path}"`
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
