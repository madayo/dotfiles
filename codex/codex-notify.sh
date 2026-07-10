#!/usr/bin/env bash

set -u

# Codex hooks はJSONを標準入力で渡す
INPUT="$(cat)"

EVENT="$(
  printf '%s' "$INPUT" |
    jq -r '.hook_event_name // "Unknown"'
)"

CWD="$(
  printf '%s' "$INPUT" |
    jq -r '.cwd // ""'
)"

SESSION_ID="$(
  printf '%s' "$INPUT" |f
    jq -r '.session_id // ""'
)"

LAST_ASSISTANT_MESSAGE="$(
  printf '%s' "$INPUT" |
    jq -r '.last_assistant_message // ""'
)"

TOOL_NAME="$(
  printf '%s' "$INPUT" |
    jq -r '.tool_name // ""'
)"

APPROVAL_DESCRIPTION="$(
  printf '%s' "$INPUT" |
    jq -r '.tool_input.description // ""'
)"

PROJECT_NAME="$(basename "${CWD:-unknown}")"
BRANCH="$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '-')"

case "$EVENT" in
  PermissionRequest)
    STATUS="承認待ち"

    if [ -n "$APPROVAL_DESCRIPTION" ]; then
      DETAIL="$APPROVAL_DESCRIPTION"
    elif [ -n "$TOOL_NAME" ]; then
      DETAIL="${TOOL_NAME} の実行確認"
    else
      DETAIL="操作の承認が必要です"
    fi
    ;;

  Stop)
    STATUS="入力待ち"
    DETAIL="$LAST_ASSISTANT_MESSAGE"
    ;;

  *)
    STATUS="確認待ち"
    DETAIL=""
    ;;
esac

SHORT_DETAIL="$(
  printf '%s' "$DETAIL" |
    jq -Rr '
      gsub("[[:space:]\r\n\t]+"; " ")
      | sub("^ "; "")
      | sub(" $"; "")
      | if length > 40 then .[:40] + "…" else . end
    '
)"

if [ -z "$SHORT_DETAIL" ] || [ "$SHORT_DETAIL" = "null" ]; then
  SHORT_DETAIL="$STATUS"
fi

TITLE="Codex"
MESSAGE="${PROJECT_NAME} / ${BRANCH} / ${STATUS} / ${SHORT_DETAIL}"

# 同一通知が短時間に重複するのを防ぐ
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/codex-notify"
mkdir -p "$CACHE_DIR"

DEDUP_KEY="$(
  printf '%s' "${SESSION_ID}|${EVENT}|${MESSAGE}" |
    sha1sum |
    awk '{print $1}'
)"

STAMP_FILE="$CACHE_DIR/$DEDUP_KEY"
NOW="$(date +%s)"
LAST=0

if [ -f "$STAMP_FILE" ]; then
  LAST="$(stat -c %Y "$STAMP_FILE" 2>/dev/null || echo 0)"
fi

if [ $((NOW - LAST)) -lt 3 ]; then
  # Stop hookは終了コード0の場合、stdoutに有効なJSONが必要
  printf '{}\n'
  exit 0
fi

touch "$STAMP_FILE"

# 古い通知キャッシュを掃除
find "$CACHE_DIR" -type f -mmin +60 -delete 2>/dev/null || true

WIN_TITLE="$(printf '%s' "$TITLE" | sed "s/'/''/g")"
WIN_MESSAGE="$(printf '%s' "$MESSAGE" | sed "s/'/''/g")"

powershell.exe \
  -NoProfile \
  -ExecutionPolicy Bypass \
  -Command "
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

\$soundPath = \"\$env:USERPROFILE\\Music\\beep-codex.wav\"

if (Test-Path \$soundPath) {
  try {
    \$player = New-Object System.Media.SoundPlayer \$soundPath
    \$player.Play()
  } catch {}
}

\$notification = New-Object System.Windows.Forms.NotifyIcon
\$notification.Icon = [System.Drawing.SystemIcons]::Information
\$notification.Visible = \$true
\$notification.BalloonTipTitle = '$WIN_TITLE'
\$notification.BalloonTipText = '$WIN_MESSAGE'
\$notification.ShowBalloonTip(5000)

# SoundPlayer.Play()は非同期なので、再生完了前に終了しないよう待機
Start-Sleep -Milliseconds 1500
Start-Sleep -Milliseconds 4000

\$notification.Dispose()
" >/dev/null 2>&1 || true

# Stop hookは終了コード0の場合、標準出力に有効なJSONが必要
printf '{}\n'

exit 0