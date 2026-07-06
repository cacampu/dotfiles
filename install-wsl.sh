#!/bin/bash
# WSL-specific setup. Run this instead of install.sh on WSL.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

log()  { printf "${GREEN}[dotfiles]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[warning]${NC} %s\n" "$1"; }

setup_wsl_conf() {
    local wsl_conf="/etc/wsl.conf"
    if [ ! -f "$wsl_conf" ] || ! grep -q "options = \"metadata\"" "$wsl_conf"; then
        log "Configuring /etc/wsl.conf for metadata support..."
        sudo tee "$wsl_conf" <<EOF >/dev/null
[automount]
options = "metadata"
EOF
        warn "WSL configuration updated."
        warn "Run 'wsl --shutdown' from PowerShell, then re-run this script."
        warn "(bootstrap.ps1 handles this restart automatically)"
        exit 3  # bootstrap.ps1 がこのコードを見て WSL を再起動する
    fi
}

install_socat() {
    if ! command -v socat &>/dev/null; then
        log "Installing socat (required for SSH agent relay)..."
        local sudo=""
        [ "$(id -u)" != "0" ] && sudo="sudo"
        $sudo apt-get install -y socat
    fi
}

setup_ssh() {
    log "Setting up SSH configuration..."
    if [ ! -f "/mnt/c/bin/npiperelay.exe" ]; then
        warn "npiperelay.exe not found. Run bootstrap.ps1 on Windows first."
        return 0
    fi

    local win_home
    win_home=$(powershell.exe -NoProfile -Command 'Write-Output $env:USERPROFILE' 2>/dev/null \
        | tr -d '\r\n' | xargs -0 wslpath 2>/dev/null)
    local win_ssh_dir="${win_home}/.ssh"

    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    ln -sf "${win_ssh_dir}/config"      "$HOME/.ssh/config"
    ln -sf "${win_ssh_dir}/known_hosts" "$HOME/.ssh/known_hosts"
    log "  SSH config linked from Windows"

    if mount | grep "/mnt/c " | grep -q "metadata"; then
        chmod 600 "${win_ssh_dir}/config" "${win_ssh_dir}/known_hosts"
        log "  Permissions fixed for Windows SSH files"
    fi
}

main() {
    log "Starting WSL dotfiles setup..."
    setup_wsl_conf
    "$DOTFILES_DIR/install.sh"
    install_socat
    setup_ssh
    log "WSL setup complete!"
}

main "$@"
