#! /bin/bash -xue

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR
source ../functions

PROMPT=">   "

# Ubuntu or Windows(MSYS) only stuff. Abort if not Ubuntu.
if [[ ! "$(cat /etc/issue 2> /dev/null)" =~ Ubuntu ]] && [[ ! "$(uname 2> /dev/null)" =~ MSYS ]] ;then
  print_error 'Only ubuntu or Windows(MSYS) is enabled.'
  exit 1
fi

# git
/bin/bash ./git.sh
/bin/bash ./package.sh
/bin/bash ./tmux.sh
/bin/bash ./tig.sh
# make symbolic link
/bin/bash ./link.sh
/bin/bash ./copmoser.sh
/bin/bash ./node.sh

print_success 'Completed! Please reopen console window.'
