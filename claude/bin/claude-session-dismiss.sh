#!/usr/bin/env bash
# Claude Code の監視リストから任意のセッションを手動で削除する。
# claude-sessions.sh に表示される session_id の先頭部分を指定して使う。
set -u

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-notify"
SESSION_DIR="$CACHE_DIR/sessions"
SESSION_PREFIX="${1:-}"

if [ -z "$SESSION_PREFIX" ]; then
  echo "usage: claude-session-dismiss.sh <session_id_prefix>" >&2
  exit 2
fi

if [ ! -d "$SESSION_DIR" ]; then
  echo "No pending Claude sessions."
  exit 0
fi

matches=()
shopt -s nullglob

for file in "$SESSION_DIR"/*.json; do
  session_id="$(jq -r '.session_id // ""' "$file" 2>/dev/null)"
  basename="${file##*/}"
  basename="${basename%.json}"

  if [[ "$session_id" == "$SESSION_PREFIX"* ]] || [[ "$basename" == "$SESSION_PREFIX"* ]]; then
    matches+=("$file")
  fi
done

case "${#matches[@]}" in
  0)
    echo "No matching Claude session: $SESSION_PREFIX" >&2
    exit 1
    ;;
  1)
    rm -f "${matches[0]}"
    echo "Dismissed: $SESSION_PREFIX"
    ;;
  *)
    echo "Multiple sessions match: $SESSION_PREFIX" >&2
    for file in "${matches[@]}"; do
      jq -r '"  " + ((.session_id // "-") | .[:12]) + "  " + (.project // "-") + "  " + (.last_user_message // "-")' "$file" 2>/dev/null
    done
    exit 1
    ;;
esac
