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
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-notify"
SESSION_DIR="$CACHE_DIR/sessions"

INPUT="$(cat)"

CWD="$(printf '%s' "$INPUT" | jq -r '.cwd // ""')"
SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // ""')"
TRANSCRIPT_PATH="$(printf '%s' "$INPUT" | jq -r '.transcript_path // ""')"
USER_PROMPT="$(printf '%s' "$INPUT" | jq -r '.user_prompt // ""')"
BACKGROUND_TASK_COUNT="$(
  printf '%s' "$INPUT" | jq -r '
    if has("background_tasks") and (.background_tasks | type == "array") then
      [.background_tasks[]] | length
    else
      0
    end
  '
)"

mkdir -p "$CACHE_DIR" "$SESSION_DIR"

session_state_file() {
  local session_id="$1"

  if [ -n "$session_id" ] && [ "$session_id" != "null" ]; then
    printf '%s/%s.json\n' "$SESSION_DIR" "$session_id"
  else
    printf '%s/%s.json\n' "$SESSION_DIR" "$(printf '%s' "$INPUT" | sha1sum | awk '{print $1}')"
  fi
}

dismiss_session_state() {
  local state_file
  state_file="$(session_state_file "$SESSION_ID")"

  rm -f "$state_file"
}

# 「未読/未処理」は Claude 側の既読概念ではなく、あくまで
# Stop 後に同一 session_id へ次の UserPromptSubmit が来ていない状態として扱う。
# UserPromptSubmit が来た時点で unread は解消し、Claude からの返答待ちとして
# waiting に更新する。セッション終了時点では監視リストから外す。
case "$NOTIFY_TYPE" in
  session_end)
    dismiss_session_state
    exit 0
    ;;
esac

PROJECT_NAME="$(basename "${CWD:-unknown}")"
BRANCH="$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '-')"

LAST_USER_MSG="$(
  if [ "$NOTIFY_TYPE" = "prompt" ] && [ -n "$USER_PROMPT" ] && [ "$USER_PROMPT" != "null" ]; then
    printf '%s\n' "$USER_PROMPT"
  else
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
  fi
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
  prompt)
    MESSAGE="⏳ ${PROJECT_NAME} / ${BRANCH} / 返答待ち / ${SHORT_MSG}"
    ;;
  permission)
    MESSAGE="🔐 ${PROJECT_NAME} / ${BRANCH} / 権限確認待ち / ${SHORT_MSG}"
    ;;
  stop|*)
    MESSAGE="🤖 ${PROJECT_NAME} / ${BRANCH} / 入力待ち / ${SHORT_MSG}"
    ;;
esac

NOW="$(date +%s)"

write_session_state() {
  local status="$1"
  local state_file
  local tmp_file

  state_file="$(session_state_file "$SESSION_ID")"
  tmp_file="${state_file}.$$"

  jq -n \
    --arg session_id "$SESSION_ID" \
    --arg status "$status" \
    --arg project "$PROJECT_NAME" \
    --arg branch "$BRANCH" \
    --arg cwd "$CWD" \
    --arg transcript_path "$TRANSCRIPT_PATH" \
    --arg last_user_message "$SHORT_MSG" \
    --argjson updated_at "$NOW" \
    '{
      session_id: $session_id,
      status: $status,
      project: $project,
      branch: $branch,
      cwd: $cwd,
      transcript_path: $transcript_path,
      last_user_message: $last_user_message,
      updated_at: $updated_at,
      updated_at_iso: ($updated_at | strftime("%Y-%m-%dT%H:%M:%SZ"))
    }' > "$tmp_file" && mv "$tmp_file" "$state_file"
}

# Stop hook は「Claude がユーザー入力待ちになった」だけでなく、
# バックグラウンドの subagent / shell / workflow などを待つために
# いったん停止した場合にも発火する。
#
# Claude Code v2.1.145 以降では Stop hook の payload に background_tasks が入り、
# ここに未完了タスクがある間は「最終的にユーザーへ制御が返った」とは言えない。
# その状態は監視リストには background として表示するが、beep / Windows 通知 /
# Slack 通知は出さない。最終的に background_tasks が空になった Stop で
# 同じ session_id の状態が unread に上書きされ、その時点で通知する。
#
# payload に background_tasks が無い古い Claude Code では上の jq が 0 に倒れるので、
# 従来通り通知する fallback になる。
if [ "$NOTIFY_TYPE" = "stop" ] && [ "$BACKGROUND_TASK_COUNT" -gt 0 ]; then
  write_session_state "background"
  exit 0
fi

case "$NOTIFY_TYPE" in
  prompt)
    write_session_state "waiting"
    exit 0
    ;;
  permission)
    write_session_state "permission"
    ;;
  stop|*)
    write_session_state "unhandled"
    ;;
esac

DEDUP_KEY="$(
  printf '%s' "${SESSION_ID}|${MESSAGE}" | sha1sum | awk '{print $1}'
)"
STAMP_FILE="$CACHE_DIR/$DEDUP_KEY"

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
