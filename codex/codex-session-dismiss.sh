#!/usr/bin/env bash
# Codexの監視リストから、指定したセッションを手動で削除する。
set -u

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/codex-notify"
SESSION_DIR="$CACHE_DIR/sessions"
AGENT_DIR="$CACHE_DIR/agents"
SESSION_PREFIX="${1:-}"

if [ -z "$SESSION_PREFIX" ]; then
  echo "usage: codex-session-dismiss.sh <session_id_prefix>" >&2
  exit 2
fi

if [ ! -d "$SESSION_DIR" ]; then
  echo "No pending Codex sessions."
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
    echo "No matching Codex session: $SESSION_PREFIX" >&2
    exit 1
    ;;
  1)
    file="${matches[0]}"
    basename="${file##*/}"
    basename="${basename%.json}"
    session_agent_dir="$AGENT_DIR/$basename"

    rm -f "$file"
    if [ -d "$session_agent_dir" ]; then
      find "$session_agent_dir" -mindepth 1 -maxdepth 1 -type f -delete 2>/dev/null || true
      rmdir "$session_agent_dir" 2>/dev/null || true
    fi
    echo "Dismissed: $SESSION_PREFIX"
    ;;
  *)
    echo "Multiple sessions match: $SESSION_PREFIX" >&2
    for file in "${matches[@]}"; do
      jq -r '
        "  "
        + ((.session_id // "-") | .[:12])
        + "  "
        + (.project // "-")
        + "  "
        + (.last_user_message // "-")
      ' "$file" 2>/dev/null
    done
    exit 1
    ;;
esac
