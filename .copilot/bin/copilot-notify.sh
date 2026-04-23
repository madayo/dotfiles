#!/usr/bin/env bash
set -u

INPUT="$(cat)"

CWD="$(printf '%s' "$INPUT" | jq -r '.cwd // ""')"
SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.sessionId // .session_id // ""')"
HOOK_EVENT_NAME="$(printf '%s' "$INPUT" | jq -r '.hookEventName // "Stop"')"
AGENT_TYPE="$(printf '%s' "$INPUT" | jq -r '.agent_type // .agentType // "Copilot"')"
TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // ""')"
TOOL_INPUT="$(printf '%s' "$INPUT" | jq -c '.tool_input // {}')"

PROJECT_NAME="$(basename "${CWD:-unknown}")"
BRANCH="$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '-')"

# PreToolUse は全ツールで発火するため、そのままだと通知過多になります。
# ここでは「ユーザー確認が発生しやすいコマンド実行系ツール」だけを通知対象に絞ります。
should_notify_for_tool_event() {
  case "$TOOL_NAME" in
    run_in_terminal|create_and_run_task|send_to_terminal|run_vscode_command|install_extension)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# ツール実行系は入力 JSON の形が少しずつ違うため、通知文に載せる代表値だけを拾います。
# 長すぎるコマンド全文をそのまま通知すると読みにくいため、1 行に潰して先頭だけ使います。
build_tool_summary() {
  local summary

  summary="$(printf '%s' "$TOOL_INPUT" | jq -r '
    .command // .task.command // .name // .url // empty
  ' 2>/dev/null)"

  summary="$(printf '%s' "$summary" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"

  if [ -z "$summary" ]; then
    summary="$TOOL_NAME"
  fi

  printf '%.80s' "$summary"
}

# PreToolUse の通知はコマンド実行系だけに限定し、その他のツール通知はここで捨てます。
case "$HOOK_EVENT_NAME" in
  PreToolUse)
    if ! should_notify_for_tool_event; then
      exit 0
    fi
    ;;
esac

TOOL_SUMMARY="$(build_tool_summary)"

case "$HOOK_EVENT_NAME" in
  PreToolUse)
    TITLE="GitHub Copilot"
    MESSAGE="${PROJECT_NAME} / ${BRANCH} / 確認待ちの可能性あり: ${TOOL_SUMMARY}"
    ;;
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