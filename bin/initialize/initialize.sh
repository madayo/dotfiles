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
# package install
/bin/bash ./package.sh
# tmux install
/bin/bash ./tmux.sh
# tig install
/bin/bash ./tig.sh
# link
/bin/bash ./link.sh
# copmoser install
/bin/bash ./copmoser.sh

print_success 'Completed! Please reopen console window.'
