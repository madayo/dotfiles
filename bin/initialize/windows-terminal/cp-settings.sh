#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../../functions"

print_info "=== Windows Terminal settings linker ==="
echo

# Store版か確認
read -p "Microsoft Store版の Windows Terminal を使っていますか？ (y/n): " STORE

if [[ "$STORE" != "y" && "$STORE" != "Y" ]]; then
  print_error "Store版ではないため中断します。非Store版パスは別途対応が必要です。"
  exit 1
fi

# Windowsユーザー名取得
WIN_USER=$(get_windows_username)

print_info "検出された Windowsユーザー名: $WIN_USER"
read -p "このユーザー名で正しいですか？ (y/n): " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  print_error "ユーザー名が一致しないため中断します。"
  exit 1
fi

SRC=$(get_dotfiles_wt_settings_path)
DST=$(get_windows_wt_settings_path)

echo
print_info "コピー元: $SRC"
print_info "コピー先: $DST"
echo

# 存在確認
if [ ! -f "$SRC" ]; then
  print_error "repo側 settings.json が存在しません。中断します。"
  exit 1
fi

if [ ! -f "$DST" ]; then
  print_error "Windows Terminal 側 settings.json が存在しません。中断します。"
  exit 1
fi

# 未コミット変更チェック
if has_uncommitted_changes "$SRC"; then
  print_error "settings.json に未コミット変更があります。"
  exit 1
fi

print_info "WSL 側のファイルを Windows Terminal 側にコピーを行います。"
read -p "続行しますか？ (y/n): " FINAL_CONFIRM

if [[ "$FINAL_CONFIRM" != "y" && "$FINAL_CONFIRM" != "Y" ]]; then
  print_error "中断しました。"
  exit 1
fi

# コピー作成
cp "$SRC" "$DST"

print_success "コピーしました。"