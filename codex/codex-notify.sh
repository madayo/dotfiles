#!/usr/bin/env bash
# Codex hooks の状態を記録し、対応が必要なイベントを通知する。
set -u
umask 077

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SLACK_WEBHOOK_FILE="${CODEX_NOTIFY_SLACK_WEBHOOK_FILE:-$SCRIPT_DIR/slack-webhook-url.txt}"
SLACK_DELAY_SECONDS="${CODEX_NOTIFY_SLACK_DELAY_SECONDS:-180}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/codex-notify"
SESSION_DIR="$CACHE_DIR/sessions"
AGENT_DIR="$CACHE_DIR/agents"
STAMP_DIR="$CACHE_DIR/stamps"

if ! [[ "$SLACK_DELAY_SECONDS" =~ ^[0-9]+$ ]]; then
  SLACK_DELAY_SECONDS=180
fi

INPUT="$(cat)"

# 通知処理の失敗でCodex本体の動作を止めない。
hook_success() {
  printf '{}\n'
  exit 0
}

if ! printf '%s' "$INPUT" | jq -e 'type == "object"' >/dev/null 2>&1; then
  hook_success
fi

EVENT="$(printf '%s' "$INPUT" | jq -r '.hook_event_name // "Unknown"')"
CWD="$(printf '%s' "$INPUT" | jq -r '.cwd // ""')"
SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // ""')"
TURN_ID="$(printf '%s' "$INPUT" | jq -r '.turn_id // ""')"
AGENT_ID="$(printf '%s' "$INPUT" | jq -r '.agent_id // ""')"
USER_PROMPT="$(printf '%s' "$INPUT" | jq -r '.prompt // ""')"
LAST_ASSISTANT_MESSAGE="$(printf '%s' "$INPUT" | jq -r '.last_assistant_message // ""')"
TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // ""')"
APPROVAL_DESCRIPTION="$(printf '%s' "$INPUT" | jq -r '.tool_input.description // ""')"

if [ -z "$SESSION_ID" ] || [ "$SESSION_ID" = "null" ]; then
  hook_success
fi

mkdir -p "$SESSION_DIR" "$AGENT_DIR" "$STAMP_DIR"

SESSION_KEY="$(printf '%s' "$SESSION_ID" | sha256sum | awk '{print $1}')"
STATE_FILE="$SESSION_DIR/$SESSION_KEY.json"
SESSION_AGENT_DIR="$AGENT_DIR/$SESSION_KEY"

project_name_from_cwd() {
  local cwd="$1"

  if [ -z "$cwd" ] || [ "$cwd" = "null" ]; then
    printf 'unknown'
    return
  fi

  printf '%s\n' "$cwd" | jq -Rr '
    rtrimstr("/")
    | if . == "" then "/"
      else
        split("/")
        | map(select(. != ""))
        | reverse
        | .[:3]
        | join(" / ")
      end
  '
}

shorten() {
  local value="$1"
  local limit="$2"

  printf '%s' "$value" | jq -Rr --argjson limit "$limit" '
    gsub("[[:space:]\r\n\t]+"; " ")
    | sub("^ "; "")
    | sub(" $"; "")
    | if length > $limit then .[:$limit] + "…" else . end
  '
}

tool_fingerprint() {
  printf '%s' "$INPUT" |
    jq -cS '{
      turn_id: (.turn_id // ""),
      tool_name: (.tool_name // ""),
      tool_input: (
        if ((.tool_name == "Bash") or (.tool_name == "apply_patch"))
          and ((.tool_input // null) | type == "object")
        then .tool_input | del(.description)
        else (.tool_input // null)
        end
      )
    }' |
    sha256sum |
    awk '{print $1}'
}

PROJECT_NAME="$(project_name_from_cwd "$CWD")"
BRANCH="$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '-')"
NOW="$(date +%s)"

current_status() {
  jq -r '.status // ""' "$STATE_FILE" 2>/dev/null || true
}

current_last_user_message() {
  jq -r '.last_user_message // ""' "$STATE_FILE" 2>/dev/null || true
}

current_pending_permissions() {
  jq -c '
    (.pending_permissions // [])
    | if type == "array" then . else [] end
  ' "$STATE_FILE" 2>/dev/null || printf '[]\n'
}

current_notification_token() {
  jq -r \
    --arg turn_id "$TURN_ID" \
    'if .status == "unhandled" and .turn_id == $turn_id
      then (.notification_token // "")
      else ""
    end' \
    "$STATE_FILE" 2>/dev/null || true
}

active_agent_count() {
  local files=()

  if [ ! -d "$SESSION_AGENT_DIR" ]; then
    printf '0\n'
    return
  fi

  shopt -s nullglob
  files=("$SESSION_AGENT_DIR"/*.json)
  shopt -u nullglob
  printf '%s\n' "${#files[@]}"
}

write_session_state() {
  local status="$1"
  local last_user_message="$2"
  local notification_token="${3:-}"
  local pending_permissions="${4:-[]}"
  local active_subagents
  local tmp_file

  active_subagents="$(active_agent_count)"
  tmp_file="${STATE_FILE}.$$"

  jq -n \
    --arg session_id "$SESSION_ID" \
    --arg status "$status" \
    --arg project "$PROJECT_NAME" \
    --arg branch "$BRANCH" \
    --arg cwd "$CWD" \
    --arg turn_id "$TURN_ID" \
    --arg last_user_message "$last_user_message" \
    --arg notification_token "$notification_token" \
    --argjson pending_permissions "$pending_permissions" \
    --argjson active_subagents "$active_subagents" \
    --argjson updated_at "$NOW" \
    '{
      session_id: $session_id,
      status: $status,
      project: $project,
      branch: $branch,
      cwd: $cwd,
      turn_id: $turn_id,
      last_user_message: $last_user_message,
      active_subagents: $active_subagents,
      pending_permissions: $pending_permissions,
      notification_token: $notification_token,
      updated_at: $updated_at,
      updated_at_iso: ($updated_at | strftime("%Y-%m-%dT%H:%M:%SZ"))
    }' > "$tmp_file" && mv "$tmp_file" "$STATE_FILE"
}

remove_agent_state() {
  if [ ! -d "$SESSION_AGENT_DIR" ]; then
    return
  fi

  find "$SESSION_AGENT_DIR" -mindepth 1 -maxdepth 1 -type f -delete 2>/dev/null || true
  rmdir "$SESSION_AGENT_DIR" 2>/dev/null || true
}

SHOULD_NOTIFY=0

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
esac

case "$EVENT" in
  PermissionRequest|Stop)
    SHORT_DETAIL="$(shorten "$DETAIL" 40)"
    if [ -z "$SHORT_DETAIL" ] || [ "$SHORT_DETAIL" = "null" ]; then
      SHORT_DETAIL="$STATUS"
    fi

    TITLE="Codex"
    MESSAGE="${PROJECT_NAME} / ${BRANCH} / ${STATUS} / ${SHORT_DETAIL}"
    DEDUP_KEY="$(printf '%s' "${SESSION_ID}|${EVENT}|${MESSAGE}" | sha256sum | awk '{print $1}')"
    STAMP_FILE="$STAMP_DIR/$DEDUP_KEY"
    ;;
esac

notification_is_recent() {
  local last=0

  if [ -f "$STAMP_FILE" ]; then
    last="$(stat -c %Y "$STAMP_FILE" 2>/dev/null || echo 0)"
  fi

  [ $((NOW - last)) -lt 3 ]
}

new_notification_token() {
  printf '%s' "${SESSION_ID}|${TURN_ID}|${NOW}|$$" |
    sha256sum |
    awk '{print $1}'
}

# 複数のサブエージェントフックが同時に状態を書き換える場合に備える。
exec 9>"$CACHE_DIR/state.lock"
flock -x 9
LAST_USER_MESSAGE="$(current_last_user_message)"

case "$EVENT" in
  SessionEnd)
    rm -f "$STATE_FILE"
    remove_agent_state
    flock -u 9
    hook_success
    ;;

  UserPromptSubmit)
    remove_agent_state
    LAST_USER_MESSAGE="$(shorten "$USER_PROMPT" 40)"
    if [ -z "$LAST_USER_MESSAGE" ] || [ "$LAST_USER_MESSAGE" = "null" ]; then
      LAST_USER_MESSAGE="(no message)"
    fi
    write_session_state "waiting" "$LAST_USER_MESSAGE"
    flock -u 9
    hook_success
    ;;

  SubagentStart)
    if [ -n "$AGENT_ID" ] && [ "$AGENT_ID" != "null" ]; then
      mkdir -p "$SESSION_AGENT_DIR"
      AGENT_KEY="$(printf '%s' "$AGENT_ID" | sha256sum | awk '{print $1}')"
      jq -n \
        --arg agent_id "$AGENT_ID" \
        --argjson updated_at "$NOW" \
        '{agent_id: $agent_id, updated_at: $updated_at}' \
        > "$SESSION_AGENT_DIR/$AGENT_KEY.json"
    fi

    case "$(current_status)" in
      permission|unhandled)
        ;;
      *)
        write_session_state "background" "$LAST_USER_MESSAGE"
        ;;
    esac
    flock -u 9
    hook_success
    ;;

  SubagentStop)
    if [ -n "$AGENT_ID" ] && [ "$AGENT_ID" != "null" ]; then
      AGENT_KEY="$(printf '%s' "$AGENT_ID" | sha256sum | awk '{print $1}')"
      rm -f "$SESSION_AGENT_DIR/$AGENT_KEY.json"
      rmdir "$SESSION_AGENT_DIR" 2>/dev/null || true
    fi

    case "$(current_status)" in
      permission|unhandled)
        ;;
      *)
        if [ "$(active_agent_count)" -gt 0 ]; then
          write_session_state "background" "$LAST_USER_MESSAGE"
        else
          write_session_state "waiting" "$LAST_USER_MESSAGE"
        fi
        ;;
    esac
    flock -u 9
    hook_success
    ;;

  PostToolUse)
    TOOL_FINGERPRINT="$(tool_fingerprint)"
    PENDING_PERMISSIONS="$(current_pending_permissions)"
    PENDING_RESULT="$(
      jq -cn \
        --argjson pending_permissions "$PENDING_PERMISSIONS" \
        --arg fingerprint "$TOOL_FINGERPRINT" \
        '($pending_permissions | index($fingerprint)) as $index
        | if $index == null then
            {matched: false, pending_permissions: $pending_permissions}
          else
            {
              matched: true,
              pending_permissions: (
                $pending_permissions[:$index]
                + $pending_permissions[($index + 1):]
              )
            }
          end'
    )"

    if [ "$(printf '%s' "$PENDING_RESULT" | jq -r '.matched')" = "true" ]; then
      PENDING_PERMISSIONS="$(printf '%s' "$PENDING_RESULT" | jq -c '.pending_permissions')"

      if [ "$(printf '%s' "$PENDING_PERMISSIONS" | jq 'length')" -gt 0 ]; then
        write_session_state "permission" "$LAST_USER_MESSAGE" "" "$PENDING_PERMISSIONS"
      elif [ "$(active_agent_count)" -gt 0 ]; then
        write_session_state "background" "$LAST_USER_MESSAGE"
      else
        write_session_state "waiting" "$LAST_USER_MESSAGE"
      fi
    fi
    flock -u 9
    hook_success
    ;;

  PermissionRequest)
    TOOL_FINGERPRINT="$(tool_fingerprint)"
    PENDING_PERMISSIONS="$(current_pending_permissions)"
    PENDING_PERMISSIONS="$(
      jq -cn \
        --argjson pending_permissions "$PENDING_PERMISSIONS" \
        --arg fingerprint "$TOOL_FINGERPRINT" \
        '$pending_permissions + [$fingerprint]'
    )"
    write_session_state "permission" "$LAST_USER_MESSAGE" "" "$PENDING_PERMISSIONS"

    if ! notification_is_recent; then
      touch "$STAMP_FILE"
      SHOULD_NOTIFY=1
    fi
    ;;

  Stop)
    if notification_is_recent; then
      NOTIFICATION_TOKEN="$(current_notification_token)"
    else
      NOTIFICATION_TOKEN=""
    fi

    if [ -z "$NOTIFICATION_TOKEN" ]; then
      NOTIFICATION_TOKEN="$(new_notification_token)"
      touch "$STAMP_FILE"
      SHOULD_NOTIFY=1
    fi
    write_session_state "unhandled" "$LAST_USER_MESSAGE" "$NOTIFICATION_TOKEN"
    ;;

  *)
    flock -u 9
    hook_success
    ;;
esac

flock -u 9

if [ "$SHOULD_NOTIFY" -ne 1 ]; then
  hook_success
fi

find "$STAMP_DIR" -type f -mmin +60 -delete 2>/dev/null || true

send_slack() {
  local message="$1"
  local slack_webhook_url
  local slack_payload

  if [ ! -f "$SLACK_WEBHOOK_FILE" ]; then
    return
  fi

  slack_webhook_url="$(tr -d '\r\n' < "$SLACK_WEBHOOK_FILE")"
  if [ -z "$slack_webhook_url" ]; then
    return
  fi

  slack_payload="$(jq -n --arg text "$message" '{text: $text}')"
  curl -sS \
    -X POST \
    -H 'Content-type: application/json' \
    --data "$slack_payload" \
    "$slack_webhook_url" \
    >/dev/null 2>&1 || true
}

send_windows_notification() {
  local title="$1"
  local message="$2"
  local win_title
  local win_message

  win_title="$(printf '%s' "$title" | sed "s/'/''/g")"
  win_message="$(printf '%s' "$message" | sed "s/'/''/g")"

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
\$notification.BalloonTipTitle = '$win_title'
\$notification.BalloonTipText = '$win_message'
\$notification.ShowBalloonTip(5000)

# SoundPlayer.Play()は非同期なので、再生完了前に終了しないよう待機
Start-Sleep -Milliseconds 1500
Start-Sleep -Milliseconds 4000

\$notification.Dispose()
" >/dev/null 2>&1 || true
}

schedule_slack_if_unhandled() {
  local message="$1"
  local state_file="$2"
  local notification_token="$3"
  local delay_seconds="$4"

  (
    sleep "$delay_seconds"

    if jq -e \
      --arg notification_token "$notification_token" \
      '.status == "unhandled" and .notification_token == $notification_token' \
      "$state_file" >/dev/null 2>&1; then
      send_slack "$message"
    fi
  ) >/dev/null 2>&1 &
}

# 通知処理はHookの応答を遅らせないようバックグラウンドで実行する。
send_windows_notification "$TITLE" "$MESSAGE" >/dev/null 2>&1 &

case "$EVENT" in
  PermissionRequest)
    send_slack "$MESSAGE" >/dev/null 2>&1 &
    ;;
  Stop)
    schedule_slack_if_unhandled \
      "$MESSAGE" \
      "$STATE_FILE" \
      "$NOTIFICATION_TOKEN" \
      "$SLACK_DELAY_SECONDS"
    ;;
esac

hook_success
