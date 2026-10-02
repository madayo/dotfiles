#!/usr/bin/env bash
# Claude Code の Stop / PermissionRequest hook が記録した監視状態を一覧表示する。
# watch と組み合わせて、返答済みだが未対応のセッションを確認するための実験用コマンド。
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-notify"
SESSION_DIR="$CACHE_DIR/sessions"
PRUNE_DAYS="${CLAUDE_SESSION_PRUNE_DAYS:-7}"

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

# status が取りうる値（claude-notify.sh の write_session_state が書き込む）:
#   waiting     UserPromptSubmit 時。Claude の返答待ち。通知なし。
#   background  Stop hook かつ background_tasks 残あり。subagent / shell 等の完了待ち。通知なし。
#   permission  PermissionRequest 時。権限確認待ち。通知あり。
#   unhandled   Stop hook 完了・次の入力なし。未対応で放置中。通知あり（beep / Win / Slack）。
# handled / closed は下の select で除外するが、現状どのスクリプトも書き込まない
# （対応済みは状態ファイルの削除で表現: session_end hook / claude-session-dismiss.sh / claude-session-prune.sh）。
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

# $1 を表示幅 $2 桁に切り詰め、足りない分は空白で埋める。
# printf の幅指定はバイト数基準で日本語が崩れるため、全角を 2 桁として数える。
fit_width() {
  if ! command -v python3 >/dev/null 2>&1; then
    printf '%-*.*s' "$2" "$2" "$1"
    return
  fi
  python3 -c '
import sys, unicodedata
text, width = sys.argv[1], int(sys.argv[2])
out, used = "", 0
for ch in text:
    w = 2 if unicodedata.east_asian_width(ch) in "WF" else 1
    if used + w > width:
        break
    out, used = out + ch, used + w
sys.stdout.write(out + " " * (width - used))
' "$1" "$2"
}

# transcript から表示用タイトルを取り出す。
# /rename で付けた名前（custom-title）を優先し、無ければ自動生成（ai-title）を使う。
# どちらも追記式なので最後の 1 件が最新。見つからなければ "-"。
session_title() {
  local transcript="$1" title

  if [ "$transcript" = "-" ] || [ ! -f "$transcript" ]; then
    printf '%s' "-"
    return
  fi

  title="$(grep -F '"type":"custom-title"' "$transcript" | tail -n 1 | jq -r '.customTitle // empty' 2>/dev/null)"
  if [ -z "$title" ]; then
    title="$(grep -F '"type":"ai-title"' "$transcript" | tail -n 1 | jq -r '.aiTitle // empty' 2>/dev/null)"
  fi
  # 表の崩れ防止: タブ・改行は空白に置き換える
  printf '%s' "${title:--}" | tr '\t\n\r' '   '
}

# 出力先が端末、または FORCE_COLOR 指定時に色を付ける（NO_COLOR が優先）。
# watch は子プロセスの標準出力をパイプにするため [ -t 1 ] が false になり、
# 単体実行時と違って色が消える。watch 経由でも付けたい場合は FORCE_COLOR=1 を渡す。
if [ -n "${NO_COLOR:-}" ]; then
  USE_COLOR=0
elif [ -t 1 ] || [ -n "${FORCE_COLOR:-}" ]; then
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

bash "$SCRIPT_DIR/claude-session-prune.sh" "$PRUNE_DAYS" >/dev/null 2>&1 || true

if [ ! -d "$SESSION_DIR" ]; then
  echo "No pending Claude sessions."
  exit 0
fi

shopt -s nullglob
files=("$SESSION_DIR"/*.json)

if [ "${#files[@]}" -eq 0 ]; then
  echo "No pending Claude sessions."
  exit 0
fi

printf '%-16s %-6s %-12s %-24s %s\n' "STATUS" "AGE" "SESSION" "TITLE" "PROJECT"
printf '%-16s %-6s %-12s %-24s %s\n' "----------------" "------" "------------" "------------------------" "------------------------------------"

now="$(date +%s)"

jq -s -r '
  sort_by(.project // "-", .updated_at // 0)
  | .[]
  | select((.status // "") != "handled" and (.status // "") != "closed")
  | [
      (.status // "-"),
      ((.updated_at // 0) | tostring),
      ((.session_id // "-") | .[:12]),
      ((.transcript_path // "") | if . == "" then "-" else . end),
      (.project // "-"),
      (.branch // "-")
    ]
  | @tsv
' "${files[@]}" | while IFS=$'\t' read -r status updated_at session transcript project branch; do
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
  # PROJECT 列: statusline と同じ絵文字で "📁 a/b/c (🌿 branch)" 形式にする。
  # project は "a / b / c" 形式で記録されているので区切りを詰める。branch が無ければ省略。
  project_field="📁 ${project// \/ //}"
  if [ -n "$branch" ] && [ "$branch" != "-" ]; then
    project_field="$project_field (🌿 $branch)"
  fi
  printf '%s %s %-12s %s %s\n' \
    "$status_field" \
    "$age_field" \
    "$session" \
    "$(fit_width "$(session_title "$transcript")" 24)" \
    "$project_field"
done
