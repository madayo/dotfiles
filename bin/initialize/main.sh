#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../functions"

bash "$SCRIPT_DIR/../../windows-terminal/cp-settings.sh"
bash "$SCRIPT_DIR/_node.sh"
bash "$SCRIPT_DIR/_gitconfig.sh"
bash "$SCRIPT_DIR/_link.sh"


echo "✔ 完了しました。ターミナルを再起動してください。"
