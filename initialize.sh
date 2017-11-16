#! /bin/bash -e

os="`uname -s`"

# OSの確認とインストールコマンドの振り分け
function set_install_cmd () {
  if [[ $os =~ ^CYGWIN.*$ ]]; then
    apt=apt-cyg
    # apt-cygのインストール
    cd ~
    wget https://raw.githubusercontent.com/transcode-open/apt-cyg/master/apt-cyg
    chmod 755 apt-cyg
    mv apt-cyg /usr/local/bin/
  fi
}

set_install_cmd
# 各種コマンドのインストール
$apt install tmux
$apt install vim
$apt install php
$apt install php-json
$apt install php-phar
$apt install php-mbstring
$apt install php-zlib
$apt install php-curl
$apt install curl
$apt install inetutils

# vimプラグイン管理ツール Dein.vim. NeoBundleは開発終了。その後継。
curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh -o /tmp/installer.sh
sh /tmp/installer.sh ~/.vim/dein

# Window * cygwinの場合はwindowsユーザディレクトリのシンボリックリンク作成
if [[ $os =~ ^CYGWIN.*$ ]]; then
  ln -s `cygpath -u $HOMEPATH` win_user_dir
fi 

### composerのグローバルインストール
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
mv ./composer.phar /usr/local/bin/
## TODO: ここらへんの処理は~/.composer/xxx.json系をgit管理下においておけば問題ないはず
## 日本向けミラーサイトをリポジトリに追加
composer config -g repos.packagist composer https://packagist.jp
## 処理を並列化して高速化
composer global require hirak/prestissimo
