#! /bin/bash -xue

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR
source ../functions

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