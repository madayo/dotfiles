#!/bin/bash

# 実行するコマンドを変数にまとめる（256色非対応ターミナル向け）
# watch は子プロセスの標準出力をパイプにするため、各スクリプト側の isatty 判定
# だけでは色が消える。FORCE_COLOR=1 を渡して各スクリプトに色付けを強制させる。
CMD="printf '\033[1;33m--- Claude Code ---\033[0m\n';"
CMD+=" FORCE_COLOR=1 bash claude/bin/claude-sessions.sh;"
CMD+=" printf '\n\n\n\033[1;36m--- Codex ---\033[0m\n';"
CMD+=" FORCE_COLOR=1 bash codex/codex-sessions.sh"

# watchコマンドを実行
watch -c -n 2 "$CMD"
