#! /bin/bash -xue

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR
source ../functions

if [[ "$(composer --version > /dev/null 2>&1; echo $?)" -ne 0 && ! "$(uname 2> /dev/null)" =~ MSYS ]] ;then
  EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig)
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")

  if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ];then
    >&2 echo 'ERROR: Invalid installer signature'
    rm composer-setup.php
    exit 1;
  else
    mkdir -p /usr/local/bin
    php composer-setup.php --quiet --install-dir=/usr/local/bin/ --filename=composer
    RESULT=$?
    rm composer-setup.php
  fi


  if [[ "$RESULT" -ne 0 ]] ;then
    print_error 'copmoser install is failed.'
    exit 1;
  else
    print_info 'composer is installed on /usr/local/bin .'
    composer global install
  fi
fi