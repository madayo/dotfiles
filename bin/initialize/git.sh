#! /bin/bash -xue

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR
source ../functions

# reinstall git
if [[ "$(cat /etc/issue 2> /dev/null)" =~ Ubuntu ]];then
  sudo apt -y remove git
  # その時点での最新版を入れる
  wget https://github.com/git/git/archive/v2.24.0.tar.gz
  tar xfz v2.24.0.tar.gz
  rm v2.24.0.tar.gz
  cd git-2.24.0
  make configure
  ./configure --prefix=/usr
  make all doc info
  sudo make install install-doc install-html install-info
  cd ../
  rm -fr git-2.24.0
  cd ${SCRIPT_DIR}
fi
# init git template dir
mkdir -p ~/.git_template/hooks

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

git remote set-url origin git@github.com:madayo/dotfiles.git
