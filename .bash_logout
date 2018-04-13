# tmuxが終了している場合に限りssh-agentを終了
if [[ -z $(printenv TMUX) ]]; then
  /bin/ssh-agent -k
fi
