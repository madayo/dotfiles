[[ "$-" != *i* ]] && return

# タイムゾーン
export TZ=JST-9

# windows環境下のHomeディレクトリへ移動
cd `cygpath -w ${HOMEPATH}`

#################################################################### alias
alias mysql='mysql --protocol TCP'
alias ll='ls -la --color=auto'
alias grep='grep --color=auto'
alias less='less -N'
# 左右に並べてdiff
alias diffv='diff --side-by-side --suppress-common-lines'
# composer 関連
# 何故か環境変数COMPOSER_HOMEとPATHの設定では動かなかったのでaliasで擬似的にパスを通す
alias composer='${COMPOSER_HOME}/composer --ansi'
alias phpunit='phpunit --color=always'
#################################################################### tmux
# 初回シェル時のみ tmux実行
if [ ${SHLVL} = 1 ]; then
    # tmux.conf側の255色設定が効かなかったので、起動オプションで255色設定を有効にする
    # 256色が有効かどうかは https://gist.github.com/kawaz/5150778 
    tmux -2
fi
#################################################################### nvm
export NVM_DIR="${HOME}/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#################################################################### ssh-agent
echo -n "ssh-agent: "
source ~/.ssh-agent-info
# ssh-agentと通信ができない場合は再起動
ssh-add -l >&/dev/null
if [ $? == 2 ] ; then
    echo -n "ssh-agent: restart...."
    ssh-agent >~/.ssh-agent-info
    source ~/.ssh-agent-info
fi
# 登録済みのキーが存在しない場合はssh-add実行
if ssh-add -l >&/dev/null ; then
    echo "ssh-agent: Identity is already stored."
else
    ssh-add
    ssh-add ~/.ssh/id_rsa_l
fi
#################################################################### デフォルトコマンドの拡張
function ssh() {
    # tmux起動時
    if [[ -n $(printenv TMUX) ]] ; then
        # 現在のペインIDの退避と背景色の書き換え
        local pane_id=`sh ~/dotfiles/bin/change_color_on_tmux_current_pane.sh $@`
        # 通常通りコマンド続行
        command ssh $@
        # デフォルトの色設定に戻す
        tmux select-pane -t $pane_id -P 'default'
    else
        command ssh $@
    fi
}
function sftp() {
    # tmux起動時
    if [[ -n $(printenv TMUX) ]] ; then
        # 現在のペインIDの退避と背景色の書き換え
        local pane_id=`sh ~/dotfiles/bin/change_color_on_tmux_current_pane.sh $@`
        # 通常通りコマンド続行
        command sftp $@
        # デフォルトの色設定に戻す
        tmux select-pane -t $pane_id -P 'default'
    else
        command sftp $@
    fi
}
