@echo off
net session > nul 2>&1

if %ERRORLEVEL% neq 0 (
  echo ŠÇ—ŽÒ‚Æ‚µ‚ÄŽÀs‚µ‚Ä‚­‚¾‚³‚¢B >&2
  exit /B 1
)

call :makeSymbolicLink .gitconfig git_global\.gitconfig
call :makeSymbolicLink .bash_profile .bash_profile
call :makeSymbolicLink .bashrc .bashrc
call :makeSymbolicLink .bash_logout .bash_logout
call :makeSymbolicLink .minttyrc .minttyrc
call :makeSymbolicLink .tmux.conf .tmux.conf
call :makeSymbolicLink .vimrc .vimrc
call :makeSymbolicLink .vim .vim 

exit /b

:makeSymbolicLink
if exist %CYGWIN_HOME%\%1 (
  move %CYGWIN_HOME%\%1 %CYGWIN_HOME%\%1.%date:~0,4%%date:~5,2%%date:~8,2%%time:~0,2%%time:~3,2%%time:~6,2%
)
if exist "%1\" (
  mklink /D %CYGWIN_HOME%\%1 %CYGWIN_HOME%\dotfiles\%2
) else if exist "%1" (
  mklink %CYGWIN_HOME%\%1 %CYGWIN_HOME%\dotfiles\%2
)
exit /b