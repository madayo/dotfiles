#! /bin/bash -xue

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../functions"

print_info "----------------------------"
print_info "Would you like to set committer information in '~/.gitconfig.local'? (y/n)"
while read -p "$PROMPT" yn; do
  case $yn in
    'y' )
      print_info '[user.name]?'
      read -p "$PROMPT" name
      print_info '[user.email]?'
      read -p "$PROMPT" email
      input="[user]
  name  = $name
  email = $email"
      echo "$input"
      print_info "Is this all right? (y/n)"

      while read -p "$PROMPT" yn; do
        case $yn in
          'y' )
            do_backup_if_present "~/.gitconfig.local"
            echo "$input" > ~/.gitconfig.local
            print_success "Committer information has been set in '~/.gitconfig.local'."
            break 2 ;;
          'n' )
            print_info "Would you like to set committer information in '~/.gitconfig.local'? (y/n)";
            break;
            ;;
        esac
      done
    ;;
    'n' ) break ;;
  esac
done