#!/bin/bash
# Claude Code statusLine コマンド
# PS1 スタイルのプロンプト情報とコンテキストウィンドウ使用量を表示する

input=$(cat)

# --- コンテキスト情報 ---
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
reasoning_level=$(echo "$input" | jq -r '[.effort.level, .model.reasoning_level, .model.reasoning.effort, .model.reasoning.effort_level, .model.reasoning_effort, .model.effort_level, .reasoning.effort_level, .reasoning.level, .reasoning_level, .effort_level, .effortLevel, .session.effort_level, .session.reasoning_level] | map(select(. != null and . != "" and . != "none" and . != "default") | tostring) | .[0] // empty')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')
worktree_name=$(echo "$input" | jq -r '.worktree.name // .workspace.git_worktree // empty')
worktree_branch=$(echo "$input" | jq -r '.worktree.branch // empty')

# --- レート制限情報（Pro/Max のみ） ---
rl_5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_5h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
rl_7d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rl_7d_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# --- 色設定 ---
# 使うテーマはこのブロックだけ編集すれば切り替えできます。
# プリセット例（必要なら下の有効行と差し替え）:
# 1) デフォルト(やや明るい青)
#    THEME_LABEL='\033[94m'
# 2) 濃い青
#    THEME_LABEL='\033[34m'
# 3) シアン寄り
#    THEME_LABEL='\033[96m'
# 4) 256色ブルー
#    THEME_LABEL='\033[38;5;75m'
COLOR_RESET='\033[0m'
THEME_DIR='\033[33m'
THEME_BRANCH='\033[35m'
THEME_MODEL='\033[33m'
THEME_REASONING='\033[93m'
THEME_LABEL='\033[94m'
THEME_RESET_TIME='\033[37m'

# --- PS1 スタイルプロンプト: dir [branch] ---
dir=$(basename "$cwd")

# git ブランチ取得（ロック競合を避けるため --no-optional-locks を使用）
branch=""
is_git_repo=0
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  is_git_repo=1
  branch=$(git -C "$cwd" --no-optional-locks branch 2>/dev/null | sed -n '/\* /s///p')
  [ -n "$branch" ] && branch=" 🌿 $branch"
fi

worktree=""
if [ -n "$worktree_name" ] && [ -n "$worktree_branch" ] && [ "$worktree_name" != "$worktree_branch" ]; then
  worktree="🌲 ${worktree_name}:${worktree_branch}"
elif [ -n "$worktree_name" ]; then
  worktree="🌲 ${worktree_name}"
elif [ -n "$worktree_branch" ]; then
  worktree="🌲 ${worktree_branch}"
elif [ "$is_git_repo" -eq 1 ]; then
  worktree="🌲 main tree"
else
  worktree="🌲 no worktree"
fi

# --- ヘルパー: 使用率に応じた色付きプログレスバーを出力 ---
# 緑(<50%) 黄(50-80%) 赤(>80%)
make_bar() {
  local pct=$1 label=$2 label_color=${3-"$THEME_LABEL"}
  echo "$pct" | awk -v label="$label" -v label_color="$label_color" '{
    len=5; filled=int($1/100*len+0.5);
    if(filled>len) filled=len;
    if($1<50)      color="\033[32m";
    else if($1<80) color="\033[33m";
    else           color="\033[31m";
    reset="\033[0m";
    bar="";
    for(i=0;i<filled;i++) bar=bar"█";
    for(i=filled;i<len;i++) bar=bar"░";
    printf " %s%s%s %s%s %.0f%%%s", label_color, label, reset, color, bar, $1, reset;
  }'
}

# epoch 秒を時刻文字列へ変換（GNU/BSD date を順に試す）
format_epoch() {
  local epoch=$1 fmt=$2
  date -d "@${epoch}" "$fmt" 2>/dev/null || date -r "$epoch" "$fmt" 2>/dev/null
}

# --- 出力組み立て ---
# プロンプトセグメント（黄: dir、マゼンタ: branch）
printf '%b📁 %s%b%b%s%b' "$THEME_DIR" "$dir" "$COLOR_RESET" "$THEME_BRANCH" "$branch" "$COLOR_RESET"

printf ' %b%s%b' "$THEME_LABEL" "$worktree" "$COLOR_RESET"

# モデル名 + 推論レベル（黄系）
if [ -n "$model" ]; then
  printf ' | %b%s%b' "$THEME_MODEL" "$model" "$COLOR_RESET"
  [ -n "$reasoning_level" ] && printf ' %b[%s]%b' "$THEME_REASONING" "$reasoning_level" "$COLOR_RESET"
fi

# コンテキストセグメント: "ctx 14%" 形式
if [ -n "$used_pct" ]; then
  printf ' |'
  make_bar "$used_pct" "ctx"
fi

# レート制限セグメント（5時間・7日間、Pro/Max のみ表示）
if [ -n "$rl_5h" ] || [ -n "$rl_7d" ]; then
  printf ' |'
  if [ -n "$rl_5h" ]; then
    rl_5h_label="${THEME_LABEL}5h"
    if [ -n "$rl_5h_reset" ]; then
      rl_5h_time=$(format_epoch "$rl_5h_reset" '+%H:%M')
      [ -n "$rl_5h_time" ] && rl_5h_label="${THEME_LABEL}5h${THEME_RESET_TIME}(⏰~${rl_5h_time})"
    fi
    make_bar "$rl_5h" "$rl_5h_label" ''
  fi
  if [ -n "$rl_7d" ]; then
    [ -n "$rl_5h" ] && printf ' |'
    rl_7d_label="${THEME_LABEL}7d"
    if [ -n "$rl_7d_reset" ]; then
      rl_7d_time=$(format_epoch "$rl_7d_reset" '+%m/%d %H:%M')
      [ -n "$rl_7d_time" ] && rl_7d_label="${THEME_LABEL}7d${THEME_RESET_TIME}(⏰~${rl_7d_time})"
    fi
    make_bar "$rl_7d" "$rl_7d_label" ''
  fi
fi

printf '\n'
