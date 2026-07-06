#!/bin/bash
# Pure Linux (non-WSL) setup. Run this instead of install.sh on desktop Linux.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

log()  { printf "${GREEN}[dotfiles]${NC} %s\n" "$1"; }

install_zed() {
    if ! command -v zed &>/dev/null; then
        log "Installing Zed..."
        curl -f https://zed.run/install.sh | sh
    else
        log "Zed already installed, skipping"
    fi
}

install_vscode() {
    if command -v code &>/dev/null; then
        log "VSCode already installed, skipping"
        return 0
    fi
    log "Installing VSCode..."
    local sudo=""
    [ "$(id -u)" != "0" ] && sudo="sudo"
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor > /tmp/packages.microsoft.gpg
    $sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg \
        /etc/apt/keyrings/packages.microsoft.gpg
    rm /tmp/packages.microsoft.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
        | $sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
    $sudo apt-get update -qq
    $sudo apt-get install -y code
}

main() {
    log "Starting Linux dotfiles setup..."
    "$DOTFILES_DIR/install.sh"
    install_zed
    install_vscode
    log "Linux setup complete!"
}

main "$@"
