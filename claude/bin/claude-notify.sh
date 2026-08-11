# ============================================
# 前提：WSL から Windows の powershell.exe が呼べること
# ============================================
# 動作確認
# powershell.exe -NoProfile -Command "Write-Output hello"
#
# ============================================
# BurntToast（Windows通知用モジュール）をインストール
# ============================================
#
# powershell.exe -NoProfile -Command "Install-Module BurntToast -Scope CurrentUser -Force"
#
# # インストール確認
# powershell.exe -NoProfile -Command "Get-InstalledModule BurntToast"
#
# ============================================
# 実行ポリシーの制約回避
# （Import-Module が失敗するため、毎回 Bypass を付ける）
# ============================================
#
# 通知テスト（これが通ればOK）
#powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Import-Module BurntToast; New-BurntToastNotification -Text 'Claude Code','作業が完了しました'"
# ============================================
# WSL 側に通知スクリプトを配置
# ============================================
# 実行権限付与
# chmod +x claude-notify.sh

#!/usr/bin/env bash
set -u

NOTIFY_TYPE="${1:-stop}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SLACK_WEBHOOK_FILE="$SCRIPT_DIR/slack-webhook-url.txt"
SLACK_DELAY_SECONDS="${CLAUDE_NOTIFY_SLACK_DELAY_SECONDS:-180}"

INPUT="$(cat)"

CWD="$(printf '%s' "$INPUT" | jq -r '.cwd // ""')"
SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // ""')"
TRANSCRIPT_PATH="$(printf '%s' "$INPUT" | jq -r '.transcript_path // ""')"

PROJECT_NAME="$(basename "${CWD:-unknown}")"
BRANCH="$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '-')"

LAST_USER_MSG="$(
  tac "$TRANSCRIPT_PATH" 2>/dev/null | jq -r '
    def flatten:
      if type == "string" then .
      elif type == "array" then map(flatten) | join(" ")
      elif type == "object" then
        if has("text") then .text | flatten
        elif has("content") then .content | flatten
        elif has("message") then .message | flatten
        else "" end
      else "" end;

    select((.type? == "user") or (.role? == "user"))
    | (.message? // .content? // .text? // "")
    | flatten
  ' 2>/dev/null | sed '/^[[:space:]]*$/d' | head -n 1
)"

SHORT_MSG="$(
  printf '%s' "$LAST_USER_MSG" | jq -Rr '
    gsub("[[:space:]\r\n\t]+"; " ")
    | sub("^ "; "")
    | sub(" $"; "")
    | if length > 24 then .[:24] + "…" else . end
  '
)"

if [ -z "$SHORT_MSG" ] || [ "$SHORT_MSG" = "null" ]; then
  SHORT_MSG="(no message)"
fi

TITLE="Claude Code"

case "$NOTIFY_TYPE" in
  permission)
    MESSAGE="🔐 ${PROJECT_NAME} / ${BRANCH} / 権限確認待ち / ${SHORT_MSG}"
    ;;
  stop|*)
    MESSAGE="🤖 ${PROJECT_NAME} / ${BRANCH} / 入力待ち / ${SHORT_MSG}"
    ;;
esac

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-notify"
mkdir -p "$CACHE_DIR"

DEDUP_KEY="$(
  printf '%s' "${SESSION_ID}|${MESSAGE}" | sha1sum | awk '{print $1}'
)"
STAMP_FILE="$CACHE_DIR/$DEDUP_KEY"

NOW="$(date +%s)"
LAST=0
if [ -f "$STAMP_FILE" ]; then
  LAST="$(stat -c %Y "$STAMP_FILE" 2>/dev/null || echo 0)"
fi

# 同一セッション・同一文言の通知が短時間で連続したら捨てる
if [ $((NOW - LAST)) -lt 3 ]; then
  exit 0
fi

touch "$STAMP_FILE"

send_slack() {
  local message="$1"

  # Slack Incoming Webhook へ通知
  # Webhook URL は Git 管理外のファイルに保存する
  if [ -f "$SLACK_WEBHOOK_FILE" ]; then
    local slack_webhook_url
    slack_webhook_url="$(tr -d '\r\n' < "$SLACK_WEBHOOK_FILE")"

    if [ -n "$slack_webhook_url" ]; then
      local slack_payload
      slack_payload="$(jq -n --arg text "$message" '{text: $text}')"
      curl -sS \
        -X POST \
        -H 'Content-type: application/json' \
        --data "$slack_payload" \
        "$slack_webhook_url" \
        >/dev/null 2>&1 || true
    fi
  fi
}

file_state() {
  local path="$1"

  if [ -f "$path" ]; then
    stat -c '%Y:%s' "$path" 2>/dev/null || echo "0:0"
  else
    echo "0:0"
  fi
}

schedule_slack_if_idle() {
  local message="$1"
  local transcript_path="$2"
  local delay_seconds="$3"
  local base_state
  base_state="$(file_state "$transcript_path")"

  (
    sleep "$delay_seconds"

    local current_state
    current_state="$(file_state "$transcript_path")"

    # Stop 後に transcript が更新されていれば、ユーザーが反応したとみなす。
    if [ "$current_state" = "$base_state" ]; then
      send_slack "$message"
    fi
  ) >/dev/null 2>&1 &
}

WIN_TITLE="$(printf '%s' "$TITLE" | sed "s/'/''/g")"
WIN_MESSAGE="$(printf '%s' "$MESSAGE" | sed "s/'/''/g")"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

\$soundPath = \"\$env:USERPROFILE\\Music\\beep-claude.wav\"

if (Test-Path \$soundPath) {
  try {
    \$player = New-Object System.Media.SoundPlayer \$soundPath
    \$player.Play()
  } catch {}
}

\$ni = New-Object System.Windows.Forms.NotifyIcon
\$ni.Icon = [System.Drawing.SystemIcons]::Information
\$ni.Visible = \$true
\$ni.BalloonTipTitle = '$WIN_TITLE'
\$ni.BalloonTipText  = '$WIN_MESSAGE'
\$ni.ShowBalloonTip(5000)

# Play() が非同期なので、すぐプロセスを終わらせない
Start-Sleep -Milliseconds 1500

Start-Sleep -Milliseconds 4000
\$ni.Dispose()
" >/dev/null 2>&1 || true

case "$NOTIFY_TYPE" in
  permission)
    send_slack "$MESSAGE"
    ;;
  stop|*)
    schedule_slack_if_idle "$MESSAGE" "$TRANSCRIPT_PATH" "$SLACK_DELAY_SECONDS"
    ;;
esac

exit 0
