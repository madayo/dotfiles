# Introduction  
It is based on the environment of `windows` and `cygwin`.
# Installation  

1. ***Download***  
- github  
    ```sh
    cd ~/
    git clone https://github.com/Yosuke-Shimada/dotfiles.git
    ```  
- cygwin  
https://cygwin.com/install.html  
    - Cygwin Setup - Select Packages  
    install `git` and `wget`  

2. ***Set environment variables***  
To enable the settings, please do the following.  
    2-1. Install [WinMerge](http://www.geocities.co.jp/SiliconValley-SanJose/8165/winmerge.html).  
    2-2. Set path installed `WinMergeU.exe` in `$WINMERGE` environment variable.  
    2-3. Set path Cygwin's home path in `$CYGWIN_HOME` environment variable.  

3. ***Create symbolic links***  
Please exec below commnads on `cmd.exe` by administrator.  
    ```bat
    dotfiles\link.bat
    ```  
4. ***Set git commiter info***  
Git `user.name` and `user.email` have not been set yet, so please set your name and email in `~/.gitconfig.local`.
    ```sh
    [user]
        name = foo
        email = bar@baz
    ```  