#!/usr/bin/env bash
set -u

INPUT="$(cat)"

CWD="$(printf '%s' "$INPUT" | jq -r '.cwd // ""')"
SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.sessionId // .session_id // ""')"
HOOK_EVENT_NAME="$(printf '%s' "$INPUT" | jq -r '.hookEventName // "Stop"')"

PROJECT_NAME="$(basename "${CWD:-unknown}")"
BRANCH="$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '-')"

case "$HOOK_EVENT_NAME" in
  *)
    TITLE="GitHub Copilot"
    MESSAGE="${PROJECT_NAME} / ${BRANCH} / 返答待ちです"
    ;;
esac

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/copilot-notify"
mkdir -p "$CACHE_DIR"

DEDUP_KEY="$({
  printf '%s' "$SESSION_ID"
  printf '|%s|%s' "$HOOK_EVENT_NAME" "$MESSAGE"
} | sha1sum | awk '{print $1}')"
STAMP_FILE="$CACHE_DIR/$DEDUP_KEY"

NOW="$(date +%s)"
LAST=0
if [ -f "$STAMP_FILE" ]; then
  LAST="$(stat -c %Y "$STAMP_FILE" 2>/dev/null || echo 0)"
fi

if [ $((NOW - LAST)) -lt 3 ]; then
  exit 0
fi

touch "$STAMP_FILE"

WIN_TITLE="$(printf '%s' "$TITLE" | sed "s/'/''/g")"
WIN_MESSAGE="$(printf '%s' "$MESSAGE" | sed "s/'/''/g")"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

\$soundPath = \"\$env:USERPROFILE\\Music\\beep2.wav\"

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

Start-Sleep -Milliseconds 1500
Start-Sleep -Milliseconds 4000
\$ni.Dispose()
" >/dev/null 2>&1 || true

exit 0