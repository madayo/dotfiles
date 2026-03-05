#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../../functions"

SRC=$(get_windows_wt_settings_path) || exit 1
DST=$(get_dotfiles_wt_settings_path)

echo "Source (Windows): $SRC"
echo "Dest   (dotfiles): $DST"
echo

[ -f "$SRC" ] || { echo "Windows側 settings.json が見つからない。中断"; exit 1; }

# dotfiles リポジトリのルート取得
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

# 未コミット変更チェック
if has_uncommitted_changes "$DST"; then
  echo "settings.json に未コミット変更があります。"
  exit 1
fi

read -p "Windows側の設定を dotfiles 側に取り込みます。上書きしますか？ (y/n): " yn
[[ "$yn" =~ ^[yY]$ ]] || { echo "中断"; exit 0; }

# 取り込み（上書き）
mkdir -p "$(dirname "$DST")"
cp -a "$SRC" "$DST"

echo
echo "✔ 取り込み完了。変更箇所は git diff で確認してください。"
