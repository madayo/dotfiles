#!/usr/bin/env bash
# Claude Code の監視リストに残った古い状態ファイルを削除する。
# SessionEnd が取れない終了や強制終了で残った監視状態の掃除に使う。
set -u

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-notify"
SESSION_DIR="$CACHE_DIR/sessions"
DAYS="${1:-7}"

if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
  echo "usage: claude-session-prune.sh [days]" >&2
  exit 2
fi

if [ ! -d "$SESSION_DIR" ]; then
  exit 0
fi

# 実験運用では SessionEnd が取れない終了や強制終了で状態ファイルが残り得る。
# mtime が指定日数より古いものは、監視対象として古すぎるので強制的に掃除する。
find "$SESSION_DIR" -type f -name '*.json' -mtime +"$DAYS" -print -delete
