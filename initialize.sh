#! /bin/bash -e

source ~/dotfiles/bin/functions

# Ubuntu-only stuff. Abort if not Ubuntu.
[[ "$(cat /etc/issue 2> /dev/null)" =~ Ubuntu ]] || print_error 'Only ubuntu is enabled.'; exit 1

# update
sudo apt update
sudo apt upgrade -y

/bin/sh ~/dotfiles/link.sh

source ~/.bashrc
