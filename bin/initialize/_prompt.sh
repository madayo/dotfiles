#! /bin/bash -xue

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../functions"

if command -v oh-my-posh >/dev/null 2>&1; then
  print_info "oh-my-posh is already installed. Skipping."
else
  print_info "Installing oh-my-posh..."
  curl -s https://ohmyposh.dev/install.sh | bash -s
  oh-my-posh --version
  print_success "oh-my-posh installed."
fi


