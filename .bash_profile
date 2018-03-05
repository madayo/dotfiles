# To the extent possible under law, the author(s) have dedicated all
# copyright and related and neighboring rights to this software to the
# public domain worldwide. This software is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along
# with this software.
# If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

# base-files version 4.2-4

# ~/.bash_profile: executed by bash(1) for login shells.

# The latest version as installed by the Cygwin Setup program can
# always be found at /etc/defaults/etc/skel/.bash_profile

# Modifying /etc/skel/.bash_profile directly will prevent
# setup from updating it.

# The copy in your home directory (~/.bash_profile) is yours, please
# feel free to customise it to create a shell
# environment to your liking.  If you feel a change
# would be benifitial to all, please feel free to send
# a patch to the cygwin mailing list.

# User dependent .bash_profile file
export PS1='\[\e[0;32m\][\u@\H]\[\e[0;0m\]\e[0;34m\]:\[\e[0;35m\]\W \[\e[0;0m\]\e[0;34m\]$ \e[0;0m\]'
# Windows用
if [[ "$(uname 2> /dev/null)" =~ MSYS ]];then
  # lnコマンドでwindowsのシンボリックリンクを作成できるようにする
  export MSYS=winsymlinks:nativestrict
  export COMPOSER_HOME="${HOME}/.composer"
  export PATH="${PATH}:${COMPOSER_HOME}/vendor/bin"
  # windowsのコンソール上で起動されることを前提としているので、minntyでは一部コマンドで対話モードが無効化されてしまう。winptyで常にラップする
  # ただし今度はパイプなどでつなぐと、 winpty stdout is not a tty とエラーになるので、linuxコマンドに結果を渡したい場合はhoge.exeと拡張子付きで実行すること
  case "$TERM" in
  screen-256color)
    # The following *.exe programs are known to require a Win32 Console
    # for interactive usage, therefore let's launch them through winpty
    # when run inside `mintty`.
    for name in node python php
    do
      case "$(type -p "$name".exe 2>/dev/null)" in
      ''|/usr/bin/*) continue;;
      esac
      alias $name="winpty $name.exe"
    done
  ;;
esac
fi
# タイムゾーン
export TZ=JST-9

# source the users bashrc if it exists
if [ -f "${HOME}/.bashrc" ] ; then
  source "${HOME}/.bashrc"
fi

# Set PATH so it includes user's private bin if it exists
# if [ -d "${HOME}/bin" ] ; then
#   PATH="${HOME}/bin:${PATH}"
# fi

# Set MANPATH so it includes users' private man if it exists
# if [ -d "${HOME}/man" ]; then
#   MANPATH="${HOME}/man:${MANPATH}"
# fi

# Set INFOPATH so it includes users' private info if it exists
# if [ -d "${HOME}/info" ]; then
#   INFOPATH="${HOME}/info:${INFOPATH}"
# fi
