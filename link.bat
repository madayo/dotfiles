@echo off
net session > nul 2>&1

if %ERRORLEVEL% neq 0 (
    echo ŠÇ—Ò‚Æ‚µ‚ÄÀs‚µ‚Ä‚­‚¾‚³‚¢B >&2
    exit /B 1
)
set /P X=.gitconfig‚Ìì¬		<nul
mklink %CYGWIN_HOME%\.gitconfig %CYGWIN_HOME%\dotfiles\git_global\.gitconfig
set /P X=.bash_profile‚Ìì¬		<nul
mklink %CYGWIN_HOME%\.bash_profile %CYGWIN_HOME%\dotfiles\.bash_profile
set /P X=.bashrc‚Ìì¬			<nul
mklink %CYGWIN_HOME%\.bashrc %CYGWIN_HOME%\dotfiles\.bashrc
set /P X=.bash_logout‚Ìì¬		<nul
mklink %CYGWIN_HOME%\.bash_logout %CYGWIN_HOME%\dotfiles\.bash_logout
set /P X=.minttyrc‚Ìì¬			<nul
mklink %CYGWIN_HOME%\.minttyrc %CYGWIN_HOME%\dotfiles\.minttyrc
set /P X=.tmux.conf‚Ìì¬		<nul
mklink %CYGWIN_HOME%\.tmux.conf %CYGWIN_HOME%\dotfiles\.tmux.conf
set /P X=.vimrc‚Ìì¬			<nul
mklink %CYGWIN_HOME%\.vimrc %CYGWIN_HOME%\dotfiles\.vimrc
set /P X=.vim‚Ìì¬			<nul
mklink /D %CYGWIN_HOME%\.vim %CYGWIN_HOME%\dotfiles\.vim
