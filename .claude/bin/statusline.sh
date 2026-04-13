#!/bin/bash
# Claude Code statusLine コマンド
# PS1 スタイルのプロンプト情報とコンテキストウィンドウ使用量を表示する

input=$(cat)

# --- コンテキスト情報 ---
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')

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

# --- 出力組み立て ---
# プロンプトセグメント（シアン: user@host、黄: dir、マゼンタ: branch）
printf '\e[36m%s@%s\e[0m:\e[33m%s\e[0m\e[35m%s\e[0m' "$user" "$host" "$dir" "$branch"

# コンテキストセグメント
if [ -n "$used_pct" ]; then
  printf ' | \e[32mContext: %.0f%% used\e[0m' "$used_pct"
  if [ -n "$input_tokens" ]; then
    printf ' (%s tokens)' "$input_tokens"
  fi
fi

# モデル名
if [ -n "$model" ]; then
  printf ' | \e[34m%s\e[0m' "$model"
fi

printf '\n'
