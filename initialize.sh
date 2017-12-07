#! /bin/bash -e

PROMPT=">   "

# Ubuntu-only stuff. Abort if not Ubuntu.
if [[ ! "$(cat /etc/issue 2> /dev/null)" =~ Ubuntu ]];then
  print_error 'Only ubuntu is enabled.'
  exit 1
fi

source ~/dotfiles/bin/functions

# update
sudo apt update
sudo apt upgrade -y

# link
/bin/bash ~/dotfiles/link.sh

# set git author
echo "----------------------------"
echo "Would you like to set committer information in '~/.gitconfig.local'? (y/n)" 
while read -p "$PROMPT" yn; do
  case $yn in
    'y' ) 
      echo '[user.name]?'
      read -p "$PROMPT" name
      echo '[user.email]?'
      read -p "$PROMPT" email
      input="[user]
  name  = $name
  email = $email"
      echo "$input"
      echo "Is this all right? (y/n)"
 
      while read -p "$PROMPT" yn; do
        case $yn in
          'y' ) 
            do_backup_if_present "~/.gitconfig.local"
            echo "$input" > ~/.gitconfig.local
            break 2 ;;
          'n' ) 
            echo "Would you like to set committer information in '~/.gitconfig.local'? (y/n)";
            break;
            ;;
        esac
      done
    ;;
    'n' ) break ;;
  esac
done

printf "\e[1;32mCompleted!\e[m\n"

source ~/.bashrc
tmux
