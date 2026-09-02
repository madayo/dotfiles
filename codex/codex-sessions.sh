#!/usr/bin/env bash
# Codex hooks が記録した、対応待ちのセッション状態を一覧表示する。
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/codex-notify"
SESSION_DIR="$CACHE_DIR/sessions"
PRUNE_DAYS="${CODEX_SESSION_PRUNE_DAYS:-7}"

age_label() {
  local updated_at="$1"
  local now
  local age

  now="$(date +%s)"
  age=$((now - updated_at))

  if [ "$age" -lt 60 ]; then
    printf '%ss' "$age"
  elif [ "$age" -lt 3600 ]; then
    printf '%sm' $((age / 60))
  elif [ "$age" -lt 86400 ]; then
    printf '%sh' $((age / 3600))
  else
    printf '%sd' $((age / 86400))
  fi
}

status_label() {
  local status="$1"

  case "$status" in
    waiting)
      printf '🟡 waiting'
      ;;
    background)
      printf '⏳ background'
      ;;
    permission)
      printf '🔐 permission'
      ;;
    unhandled)
      printf '🔴 unhandled'
      ;;
    *)
      printf '%s' "$status"
      ;;
  esac
}

bash "$SCRIPT_DIR/codex-session-prune.sh" "$PRUNE_DAYS" >/dev/null 2>&1 || true

if [ ! -d "$SESSION_DIR" ]; then
  echo "No pending Codex sessions."
  exit 0
fi

shopt -s nullglob
files=("$SESSION_DIR"/*.json)

if [ "${#files[@]}" -eq 0 ]; then
  echo "No pending Codex sessions."
  exit 0
fi

printf '%-16s %-6s %-12s %-36s %-18s %s\n' \
  "STATUS" "AGE" "SESSION" "PROJECT" "BRANCH" "LAST USER MESSAGE"
printf '%-16s %-6s %-12s %-36s %-18s %s\n' \
  "----------------" "------" "------------" "------------------------------------" "------------------" "------------------------"

jq -s -r '
  sort_by(.updated_at // 0)
  | .[]
  | select((.status // "") != "handled" and (.status // "") != "closed")
  | [
      (.status // "-"),
      ((.updated_at // 0) | tostring),
      ((.session_id // "-") | .[:12]),
      (.project // "-"),
      (.branch // "-"),
      (.last_user_message // "-")
    ]
  | @tsv
' "${files[@]}" | while IFS=$'\t' read -r status updated_at session project branch message; do
  printf '%-16s %-6s %-12s %-36.36s %-18.18s %s\n' \
    "$(status_label "$status")" \
    "$(age_label "$updated_at")" \
    "$session" \
    "$project" \
    "$branch" \
    "$message"
done
