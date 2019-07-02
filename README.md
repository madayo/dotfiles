# 想定環境  
メインの開発は仮想環境上で行うが、Windows(MSYS)も必要最低限の環境構築を行う構成になっている。  

## 自動起動やインストール、各種設定を行うか？  

||Windows<br>(MSYS)|Ubuntu|
|:---|:---:|:---:|
|ssh-agent|◯|◯|
|ターミナルの見た目|◯|◯|
|tmux|◯|◯|
|vim|◯|◯|
|git|◯|◯|
|php|-|◯|
|composer|-|◯|

# Ubuntu  
```sh
cd ~/
git clone https://github.com/madayo/dotfiles.git
cd dotfiles
/bin/bash ./bin/initialize/initialize.sh
git remote set-url origin git@github.com:madayo/dotfiles.git
```  
# Windows(MSYS)  
## MSYS2のインストール  
http://www.msys2.org/
```sh
pacman -Syu --noconfirm
# 何も更新されなくなるまで何度か実行する。
pacman -Sy git --noconfirm
```  
### 環境変数追加  
- `MSYS2_PATH_TYPE`
`inherit`  
windows 側の環境変数を引き継ぐ。  
- `MSYS`  
`winsymlinks:nativestrict`  
`ln -s` windows ネイティブのシンボリックリンクが作成される。ただし、コンソールを管理者権限で起動していることが条件となる。  
## initialize  
*管理者権限でコンソールを起動しておくこと*  
```sh
cd ~/
git clone https://github.com/madayo/dotfiles.git
cd dotfiles
/bin/bash ./bin/initialize/initialize.sh
```  

# 背景画像の設定  
mintty 単体で起動する場合は背景画像の使用が可能。  
tmux と連携すると表示できなくなる。  
dotfiles/file/wallpaper.jpg を参照しているので、好きな画像をシンボリックリンクに設定する。  
```sh
cd image
ln -sf aurora_12.jpg wallpaper.jpg
```  
透過度をいじりたいときは以下を変更する。  
```sh
$ grep 'wallpaper' .minttyrc
Background=~/dotfiles/image/wallpaper.jpg,100
```  

