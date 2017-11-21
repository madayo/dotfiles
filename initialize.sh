#! /bin/bash -e

os="`uname -s`"

# apt-cygのインストール
cd ~
wget https://raw.githubusercontent.com/transcode-open/apt-cyg/master/apt-cyg
chmod 755 apt-cyg
mv apt-cyg /usr/local/bin/
apt-cyg -m ftp://ftp.iij.ad.jp/pub/cygwin/ update

# 各種コマンドのインストール
apt-cyg install tmux
apt-cyg install vim pyhton3 python3-devel python3-pip
apt-cyg install php php-json php-phar php-mbstring php-zlib php-curl
apt-cyg install curl inetutils

# vimプラグイン管理ツール Dein.vim. NeoBundleは開発終了。その後継。
curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh -o /tmp/installer.sh
sh /tmp/installer.sh ~/.vim/dein
# neovim
pip3 install neovim

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

# windowsユーザディレクトリのシンボリックリンク作成
ln -s `cygpath -u $HOMEPATH` win_user_dir

source ~/.bashrc
