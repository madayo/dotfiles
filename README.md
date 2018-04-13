# 想定環境  
メインの開発は仮想環境上で行うが、Windows(MSYS)も必要最低限の環境構築を行う構成になっている。  

## 自動起動やインストール、各種設定を行うか？  

||Windows<br>(MSYS)|Ubuntu|
|:---|:---:|:---:|
|ssh-agent|◯|◯|
|ターミナルの見た目|◯|◯|
|tmux|-|◯|
|vim|◯|◯|
|git|◯|◯|
|php|-|◯|
|composer|-|◯|

# Ubuntu  
```sh
cd ~/
git clone https://github.com/Yosuke-Shimada/dotfiles.git
cd dotfiles
/bin/bash initialize.sh
```  
# Windows(MSYS)  
## MSYS2のインストール  
http://www.msys2.org/
```sh
pacman -Syu --noconfirm
# 何も更新されなくなるまで何度か実行する。
pacman -Sy git --noconfirm
```  
環境変数追加`MSYS2_PATH_TYPE`に`inherit`を設定する。  
## initialize  
*管理者権限でコンソールを起動しておくこと*  
```sh
cd ~/
git clone https://github.com/Yosuke-Shimada/dotfiles.git
cd dotfiles
/bin/bash initialize.sh
```  
