#! /bin/bash -xue

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if command -v volta >/dev/null 2>&1; then
  echo "Volta is already installed. Skipping."
else
  echo "Installing Volta..."
  curl https://get.volta.sh | bash
  echo "Volta installed."
fi
