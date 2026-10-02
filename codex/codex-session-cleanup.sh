#!/usr/bin/env bash
# app-server の JSON-RPC を使って古い Codex セッションを確認・削除する。
set -euo pipefail

DAYS=30
DELETE=0
ASSUME_YES=0
JSON_OUTPUT=0
CURRENT_THREAD_ID="${CODEX_THREAD_ID:-}"

usage() {
  cat <<'EOF'
Usage: codex-session-cleanup.sh [OPTIONS]

古いセッションを一覧表示する（デフォルトは30日より古いもの）。
一覧表示は dry-run。削除時は番号で対象を選択する。

  --days DAYS   DAYS日より古いセッションを対象にする（default: 30）
  --delete      対象セッションを app-server 経由で削除する
  --yes         --delete で全件削除し、番号選択を省略する
  --json        一覧をJSON Linesで出力する
  -h, --help    このヘルプを表示する
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --days)
      [ "$#" -ge 2 ] || { echo "--days requires a value" >&2; exit 2; }
      DAYS="$2"
      shift 2
      ;;
    --delete) DELETE=1; shift ;;
    --yes) ASSUME_YES=1; shift ;;
    --json) JSON_OUTPUT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
  echo "--days must be a non-negative integer" >&2
  exit 2
fi
if [ "$ASSUME_YES" -eq 1 ] && [ "$DELETE" -eq 0 ]; then
  echo "--yes requires --delete" >&2
  exit 2
fi
for command in codex jq date; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "required command not found: $command" >&2
    exit 127
  }
done

cutoff="$(( $(date +%s) - DAYS * 86400 ))"
tmp_candidates="$(mktemp)"
tmp_selected=''
app_server_log="$(mktemp)"
rpc_id=0
rpc_in=''
rpc_out=''
app_server_pid=''

cleanup() {
  [ -z "$rpc_in" ] || eval "exec ${rpc_in}>&-" 2>/dev/null || true
  [ -z "$rpc_out" ] || eval "exec ${rpc_out}<&-" 2>/dev/null || true
  [ -z "$app_server_pid" ] || kill "$app_server_pid" 2>/dev/null || true
  [ -z "$app_server_pid" ] || wait "$app_server_pid" 2>/dev/null || true
  rm -f "$tmp_candidates" "$tmp_selected"
  rm -f "$app_server_log"
}
trap cleanup EXIT

coproc CODEX_APP_SERVER { codex app-server --listen stdio:// 2>"$app_server_log"; }
app_server_pid="$CODEX_APP_SERVER_PID"
eval "exec {rpc_in}>&\"${CODEX_APP_SERVER[1]}\""
eval "exec {rpc_out}<&\"${CODEX_APP_SERVER[0]}\""

rpc() {
  local method="$1" params="$2" response
  rpc_id=$((rpc_id + 1))
  printf '%s\n' "$(jq -cn --arg method "$method" --argjson id "$rpc_id" --argjson params "$params" \
    '{jsonrpc:"2.0",method:$method,id:$id,params:$params}')" >&"$rpc_in"
  while IFS= read -r response <&"$rpc_out"; do
    if jq -e --argjson id "$rpc_id" '(.id? != null) and (.id == $id)' >/dev/null 2>&1 <<<"$response"; then
      if jq -e '.error? != null' >/dev/null 2>&1 <<<"$response"; then
        jq -c '.error' <<<"$response" >&2
        return 1
      fi
      jq -c '.result' <<<"$response"
      return 0
    fi
  done
  echo "app-server closed before replying to $method" >&2
  return 1
}

rpc initialize '{"clientInfo":{"name":"codex-session-cleanup","title":"Codex session cleanup","version":"0.1.0"}}' >/dev/null
printf '%s\n' '{"jsonrpc":"2.0","method":"initialized","params":{}}' >&"$rpc_in"

list_threads() {
  local archived="$1" cursor='' result params
  while :; do
    params="$(jq -cn --argjson archived "$archived" --arg cursor "$cursor" \
      '{limit:100,sortKey:"updated_at",sortDirection:"asc",archived:$archived,
        cursor:(if $cursor == "" then null else $cursor end)}')"
    result="$(rpc thread/list "$params")"
    jq -c --argjson cutoff "$cutoff" --argjson archived "$archived" --arg current_thread_id "$CURRENT_THREAD_ID" \
      '.data[]
       | select((.updatedAt // 0) < $cutoff)
       | select((.ephemeral // false) | not)
       | select((.status.type // "unknown") != "active")
       | select($current_thread_id == "" or .id != $current_thread_id)
       | . + {archived: $archived}' <<<"$result" >>"$tmp_candidates"
    cursor="$(jq -r '.nextCursor // empty' <<<"$result")"
    [ -n "$cursor" ] || break
  done
}

# archived=false は通常一覧、archived=true はアーカイブ領域。
list_threads false
list_threads true

last_user_message() {
  local thread_id="$1" items
  items="$(rpc thread/items/list "$(jq -cn --arg thread_id "$thread_id" \
    '{threadId:$thread_id,limit:100,sortDirection:"desc"}')" 2>/dev/null || printf '{"data":[]}')"
  jq -r '[.data[]?.item
          | select(.type == "userMessage")
          | .content[]?
          | select(.type == "text")
          | .text] | first // ""' <<<"$items" \
    | tr '\r\n\t' '   ' | sed 's/  */ /g'
}

shorten_cwd() {
  local cwd="$1"

  printf '%s\n' "$cwd" | jq -Rr '
    if . == "" or . == "-" then .
    elif startswith("/") then
      "/" + (split("/") | map(select(length > 0)) | .[-3:] | join("/"))
    else
      split("/") | .[-3:] | join("/")
    end
  '
}

if [ "$JSON_OUTPUT" -eq 1 ]; then
  while IFS= read -r thread; do
    [ -n "$thread" ] || continue
    id="$(jq -r '.id' <<<"$thread")"
    cwd="$(jq -r '.cwd // "-"' <<<"$thread")"
    cwd="$(shorten_cwd "$cwd")"
    jq -c --arg cwd "$cwd" --arg message "$(last_user_message "$id")" \
      '. + {cwd:$cwd,lastUserMessage:$message}' <<<"$thread"
  done <"$tmp_candidates"
else
  printf 'cutoff: %s (%s days)\n' "$(date -d "@$cutoff" '+%Y-%m-%d %H:%M:%S %Z')" "$DAYS"
  printf '%-4s %-36s %-16s %-9s %-32s %-32s %s\n' \
    '#' 'ID' 'UPDATED' 'STATUS' 'DIRECTORY' 'TITLE' 'LAST USER MESSAGE'
  printf '%-4s %-36s %-16s %-9s %-32s %-32s %s\n' \
    '---' '------------------------------------' '----------------' '---------' '--------------------------------' '--------------------------------' '------------------------'
  count=0
  while IFS= read -r thread; do
    [ -n "$thread" ] || continue
    count=$((count + 1))
    id="$(jq -r '.id' <<<"$thread")"
    message="$(last_user_message "$id")"
    title="$(jq -r '.name // .preview // "(untitled)"' <<<"$thread" | tr '\r\n\t' '   ' | sed 's/  */ /g')"
    cwd="$(jq -r '.cwd // "-"' <<<"$thread" | tr '\r\n\t' '   ' | sed 's/  */ /g')"
    cwd="$(shorten_cwd "$cwd")"
    updated="$(jq -r '.updatedAt // 0' <<<"$thread")"
    updated_label="$(date -d "@$updated" '+%Y-%m-%d %H:%M' 2>/dev/null || printf '-')"
    status="$(jq -r '.status.type // "unknown"' <<<"$thread")"
    archived="$(jq -r 'if .archived then "archived" else "active-list" end' <<<"$thread")"
    printf '%-4s %-36s %-16s %-9s %-32.32s %-32.32s %s [%s]\n' \
      "$count" "$id" "$updated_label" "$status" "$cwd" "$title" "${message:--}" "$archived"
  done <"$tmp_candidates"
  if [ "$count" -eq 0 ]; then
    echo '対象セッションはありません。'
    exit 0
  fi
  printf '\n対象: %s件（実行中のセッションは除外）\n' "$count"
fi

[ "$DELETE" -eq 1 ] || exit 0

tmp_selected="$tmp_candidates.selected"

if [ "$ASSUME_YES" -eq 0 ]; then
  candidate_count="$(wc -l <"$tmp_candidates")"
  printf '削除する番号を入力してください（例: 1,3）。空欄でキャンセル: ' >&2
  read -r selection
  if [ -z "$selection" ]; then
    echo '削除をキャンセルしました。' >&2
    exit 0
  fi

  declare -A selected_numbers=()
  selection="${selection//,/ }"
  for number in $selection; do
    if ! [[ "$number" =~ ^[0-9]+$ ]] || [ "$number" -lt 1 ] || [ "$number" -gt "$candidate_count" ]; then
      echo "無効な番号です: $number" >&2
      exit 2
    fi
    selected_numbers["$number"]=1
  done

  number=0
  while IFS= read -r thread; do
    [ -n "$thread" ] || continue
    number=$((number + 1))
    if [ "${selected_numbers[$number]+yes}" = yes ]; then
      printf '%s\n' "$thread" >>"$tmp_selected"
    fi
  done <"$tmp_candidates"
else
  cp "$tmp_candidates" "$tmp_selected"
fi

deleted=0
failed=0
while IFS= read -r thread; do
  [ -n "$thread" ] || continue
  id="$(jq -r '.id' <<<"$thread")"
  if rpc thread/delete "$(jq -cn --arg thread_id "$id" '{threadId:$thread_id}')" >/dev/null; then
    printf 'deleted\t%s\n' "$id"
    deleted=$((deleted + 1))
  else
    printf 'failed\t%s\n' "$id" >&2
    failed=$((failed + 1))
  fi
done <"$tmp_selected"
printf '削除完了: %s件、失敗: %s件\n' "$deleted" "$failed" >&2
[ "$failed" -eq 0 ]
