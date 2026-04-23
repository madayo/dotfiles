#!/bin/bash
# Claude Code statusLine コマンド
# PS1 スタイルのプロンプト情報とコンテキストウィンドウ使用量を表示する

input=$(cat)

# --- コンテキスト情報 ---
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')

# --- レート制限情報（Pro/Max のみ） ---
rl_5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_5h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
rl_7d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rl_7d_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# --- PS1 スタイルプロンプト: user@host:dir [branch] ---
user=$(whoami)
host=$(hostname -s)
dir=$(basename "$cwd")

# git ブランチ取得（ロック競合を避けるため --no-optional-locks を使用）
branch=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks branch 2>/dev/null | sed -n '/\* /s///p')
  [ -n "$branch" ] && branch=" $branch"
fi

# --- ヘルパー: 使用率に応じた色付きプログレスバーを出力 ---
# 緑(<50%) 黄(50-80%) 赤(>80%)
make_bar() {
  local pct=$1 label=$2
  echo "$pct" | awk -v label="$label" '{
    len=5; filled=int($1/100*len+0.5);
    if(filled>len) filled=len;
    if($1<50)      color="\033[32m";
    else if($1<80) color="\033[33m";
    else           color="\033[31m";
    reset="\033[0m";
    bar="";
    for(i=0;i<filled;i++) bar=bar"█";
    for(i=filled;i<len;i++) bar=bar"░";
    printf " %s%s:%s %.0f%%%s", color, label, bar, $1, reset;
  }'
}

# --- 出力組み立て ---
# プロンプトセグメント（シアン: user@host、黄: dir、マゼンタ: branch）
printf '\e[36m%s@%s\e[0m:\e[33m%s\e[0m\e[35m%s\e[0m' "$user" "$host" "$dir" "$branch"

# コンテキストセグメント: "Context: Xk/200k (14%)" 形式、使用率で色変化
if [ -n "$used_pct" ] && [ -n "$ctx_size" ]; then
  used_tokens=$(echo "$used_pct $ctx_size" | awk '{printf "%.1fk", ($1 / 100 * $2) / 1000}')
  ctx_size_k=$(echo "$ctx_size" | awk '{printf "%dk", $1 / 1000}')
  printf ' |'
  make_bar "$used_pct" "Context: ${used_tokens}/${ctx_size_k}"
fi

# モデル名
if [ -n "$model" ]; then
  printf ' | \e[34m%s\e[0m' "$model"
fi

# レート制限セグメント（5時間・7日間、Pro/Max のみ表示）
if [ -n "$rl_5h" ] || [ -n "$rl_7d" ]; then
  printf ' |'
  if [ -n "$rl_5h" ]; then
    make_bar "$rl_5h" "5h"
    [ -n "$rl_5h_reset" ] && printf ' \e[37m ~ %s\e[0m' "$(date -d "@${rl_5h_reset}" '+%H:%M' 2>/dev/null)"
  fi
  if [ -n "$rl_7d" ]; then
    make_bar "$rl_7d" "7d"
    [ -n "$rl_7d_reset" ] && printf ' \e[37m ~ %s\e[0m' "$(date -d "@${rl_7d_reset}" '+%m/%d %H:%M' 2>/dev/null)"
  fi
fi

printf '\n'
