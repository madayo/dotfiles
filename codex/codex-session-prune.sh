#!/usr/bin/env bash
# SessionEndを取得できず残った古いCodexセッション状態を削除する。
set -u

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/codex-notify"
SESSION_DIR="$CACHE_DIR/sessions"
AGENT_DIR="$CACHE_DIR/agents"
DAYS="${1:-7}"

if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
  echo "usage: codex-session-prune.sh [days]" >&2
  exit 2
fi

if [ ! -d "$SESSION_DIR" ]; then
  exit 0
fi

find "$SESSION_DIR" -type f -name '*.json' -mtime +"$DAYS" -print -delete

if [ ! -d "$AGENT_DIR" ]; then
  exit 0
fi

shopt -s nullglob
for session_agent_dir in "$AGENT_DIR"/*; do
  session_key="${session_agent_dir##*/}"

  if [ ! -f "$SESSION_DIR/$session_key.json" ]; then
    find "$session_agent_dir" -mindepth 1 -maxdepth 1 -type f -delete 2>/dev/null || true
    rmdir "$session_agent_dir" 2>/dev/null || true
  fi
done
