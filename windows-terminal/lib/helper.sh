#!/usr/bin/env bash

get_windows_username() {
  local win_user

  win_user=$(
    powershell.exe -NoProfile -Command \
      "[Console]::OutputEncoding=[Text.UTF8Encoding]::new(); \$env:USERNAME" \
    | tr -d '\r'
  )

  if [ -z "$win_user" ]; then
    echo "Windowsユーザー名の取得に失敗しました。" >&2
    return 1
  fi

  echo "$win_user"
}

# dotfiles 側 settings.json のパス
get_dotfiles_wt_settings_path() {
  echo "$HOME/dotfiles/windows-terminal/settings.json"
}

# Windows Terminal 実際の settings.json パス（Store版前提）
get_windows_wt_settings_path() {
  local win_user
  win_user=$(get_windows_username) || return 1

  local wt_path="/mnt/c/Users/$win_user/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"

  if [ ! -d "$(dirname "$wt_path")" ]; then
    echo "Windows Terminal のパスが存在しません。Store版ですか？" >&2
    return 1
  fi

  echo "$wt_path"
}

has_uncommitted_changes() {
  local target="$1"

  if [ -z "$target" ]; then
    echo "対象ファイルが指定されていません。" >&2
    return 2
  fi

  # ワークツリー差分
  if ! git diff --quiet -- "$target"; then
    return 0
  fi

  # index（add済み未commit）
  if ! git diff --cached --quiet -- "$target"; then
    return 0
  fi

  # staged（add済み未commit）
  if ! git diff --staged --quiet -- "$target"; then
    return 0
  fi

  return 1
}