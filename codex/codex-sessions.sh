#!/usr/bin/env bash
# Codex hooks が記録した、対応待ちのセッション状態を一覧表示する。
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/codex-notify"
SESSION_DIR="$CACHE_DIR/sessions"
PRUNE_DAYS="${CODEX_SESSION_PRUNE_DAYS:-7}"

age_label() {
  local updated_at="$1"
  local now="${2:-$(date +%s)}"
  local age=$((now - updated_at))

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

# status が取りうる値（codex-notify.sh の write_session_state が書き込む）:
#   waiting     ユーザー入力送信時。Codex の返答待ち。通知なし。
#   background  subagent 実行中（active_agent_count > 0）。その完了待ち。通知なし。
#   permission  権限確認待ち。通知あり。
#   unhandled   応答完了・次の入力なし。未対応で放置中。通知あり。
# handled / closed は下の select で除外するが、現状どのスクリプトも書き込まない
# （対応済みは状態ファイルの削除で表現: session 終了 / codex-session-dismiss.sh / codex-session-prune.sh）。
# 未知の値はそのまま素通しで表示する。
#
# 待ち先による分類:
#   AI 待ち（待つだけ・強調不要）      … waiting / background
#   自分のアクション待ち（要対応・強調）… permission / unhandled → STATUS 列を太字赤にする
status_is_actionable() {
  case "$1" in
    permission | unhandled) return 0 ;;
    *) return 1 ;;
  esac
}

status_label() {
  local status="$1"

  case "$status" in
    waiting)
      printf '🤖 waiting'
      ;;
    background)
      printf '⏳ background'
      ;;
    permission)
      printf '🔐 permission'
      ;;
    unhandled)
      printf '👀 unhandled'
      ;;
    *)
      printf '%s' "$status"
      ;;
  esac
}

# 出力先が端末で、かつ NO_COLOR が未設定のときだけ色を付ける。
# パイプ・リダイレクト時は生の ANSI を混ぜない。watch -c は端末扱いなので色が出る。
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  USE_COLOR=1
else
  USE_COLOR=0
fi

# $1 を太字赤で巻く（USE_COLOR=0 なら素通し）。パディング済み文字列を渡すこと。
paint_alert() {
  if [ "$USE_COLOR" = 1 ]; then
    printf '\033[1;31m%s\033[0m' "$1"
  else
    printf '%s' "$1"
  fi
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

now="$(date +%s)"

jq -s -r '
  sort_by(.project // "-", .updated_at // 0)
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
  # 色分けルール（ANSI 分で桁がずれないよう、先にパディングしてから色を巻く）:
  #   STATUS 列 … 自分のアクション待ち（permission / unhandled）のみ太字赤。AI 待ちは色なし。
  #   AGE 列    … updated_at から 1 日（86400 秒）以上経過した行のみ太字赤。1 日未満は色なし。
  #               updated_at 欠損時は 0 起点で巨大値になり赤くなる。
  status_field="$(printf '%-16s' "$(status_label "$status")")"
  if status_is_actionable "$status"; then
    status_field="$(paint_alert "$status_field")"
  fi
  age_field="$(printf '%-6s' "$(age_label "$updated_at" "$now")")"
  if [ "$((now - updated_at))" -ge 86400 ]; then
    age_field="$(paint_alert "$age_field")"
  fi
  printf '%s %s %-12s %-36.36s %-18.18s %s\n' \
    "$status_field" \
    "$age_field" \
    "$session" \
    "$project" \
    "$branch" \
    "$message"
done
