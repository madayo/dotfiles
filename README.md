# Introduction#  
It is based on the environment of `windows` and `cygwin`.
# Installation  
1. ** *Download* **  
```sh
cd ~/
git clone hoge
```  
2. ** *Create symbolic links* **  
Please exec below commnads on `cmd.exe` by administrator.
```bat
dotfiles\link.bat
```  
3. ** *Set git commiter info* **  
Git `user.name` and `user.email` have not been set yet, so please set your name and email in `~/.gitconfig.local`.
```sh
[user]
    name = foo
    email = bar@baz
```
4. ** *Set environment variables* **  
To enable the following settings, please do the following.
```
[difftool "WinMerge"]
    cmd = `cygpath $WINMERGE` -f '*.*' -e -u -dl 'WorkTree' -dr 'Repository' -wr \"`cygpath -w ${REMOTE}`\" \"`cygpath -w ${LOCAL}`\"
[mergetool "WinMerge"]
    cmd = `cygpath $WINMERGE` -e -r -u \"{$LOCAL}\" \"${REMOTE}\" \"${MERGED}\"
```  
    1. Install [WinMerge](http://www.geocities.co.jp/SiliconValley-SanJose/8165/winmerge.html).  
    2. Set path installed `WinMergeU.exe` in `$WINMERGE` environment variable.


CYGWIN_HOMEにホームディレクトリを設定