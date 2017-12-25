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
pacman -Sy --noconfirm
pacman -Sy git tmux vim curl --noconfirm
```  
## initialize  
*管理者権限でコンソールを起動しておくこと*  
```sh
cd ~/
git clone https://github.com/Yosuke-Shimada/dotfiles.git
cd dotfiles
export MSYS=winsymlinks:nativestrict
/bin/bash initialize.sh
```  
## 必要に応じて各種シンボリックリンク作成
```sh
# ssh
ln -s /c/Users/simada/Documents/.ssh/ ~/.ssh
# viコマンド
ln -s /usr/bin/vim /usr/bin/vi
```  
