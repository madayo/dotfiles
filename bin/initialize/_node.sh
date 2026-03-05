#! /bin/bash -xue

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../functions"

if command -v volta >/dev/null 2>&1; then
  print_info "Volta is already installed. Skipping."
else
  print_info "Installing Volta..."
  curl https://get.volta.sh | bash
  print_success "Volta installed."
fi
