#! /bin/bash -e
tmux set -g status-left-length 50
# [{Session}:{Window}:{Pane}][{login_user:hostname] のフォーマット
tmux set -g status-left "#{?client_prefix,#[reverse],}#[fg=green][#S:#I.#P]#[fg=yellow][#(whoami)@#h]  "
