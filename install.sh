#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

log()  { printf "${GREEN}[dotfiles]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[warning]${NC} %s\n" "$1"; }

install_packages() {
    if command -v apt-get &>/dev/null; then
        log "Installing base packages..."
        local sudo=""
        [ "$(id -u)" != "0" ] && sudo="sudo"
        $sudo apt-get update -qq
        $sudo apt-get install -y curl git zsh build-essential unzip
    else
        warn "Non-apt system detected. Ensure curl, git, zsh, build-essential are installed."
    fi
}

install_mise() {
    if ! command -v mise &>/dev/null; then
        log "Installing mise..."
        curl https://mise.run | sh
        export PATH="$HOME/.local/bin:$PATH"
    else
        log "mise already installed, skipping"
    fi
}

install_fzf() {
    local fzf_dir="$HOME/.local/share/fzf"
    if [ ! -d "$fzf_dir" ]; then
        log "Installing fzf..."
        git clone --depth 1 https://github.com/junegunn/fzf.git "$fzf_dir"
        "$fzf_dir/install" --bin
    else
        log "fzf already installed, skipping"
    fi
}

install_omz() {
    local omz_dir="$HOME/.local/share/oh-my-zsh"
    if [ ! -d "$omz_dir" ]; then
        log "Installing oh-my-zsh..."
        ZSH="$omz_dir" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
    else
        log "oh-my-zsh already installed, skipping"
    fi

    local plugins_dir="$omz_dir/custom/plugins"
    if [ ! -d "$plugins_dir/zsh-syntax-highlighting" ]; then
        log "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugins_dir/zsh-syntax-highlighting"
    fi
    if [ ! -d "$plugins_dir/zsh-autosuggestions" ]; then
        log "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions.git "$plugins_dir/zsh-autosuggestions"
    fi
}

install_starship() {
    if ! command -v starship &>/dev/null; then
        log "Installing starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- --yes
    else
        log "starship already installed, skipping"
    fi
}

install_rust() {
    if ! command -v rustup &>/dev/null; then
        log "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    else
        log "Rust already installed, skipping"
    fi
}

install_gh() {
    if command -v gh &>/dev/null; then
        log "GitHub CLI already installed, skipping"
        return 0
    fi
    if ! command -v apt-get &>/dev/null; then
        warn "Non-apt system detected. Install gh manually: https://cli.github.com/"
        return 0
    fi
    log "Installing GitHub CLI..."
    local sudo=""
    [ "$(id -u)" != "0" ] && sudo="sudo"
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | $sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    $sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | $sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    $sudo apt-get update -qq
    $sudo apt-get install -y gh
}

install_claude_code() {
    if command -v claude &>/dev/null; then
        log "Claude Code already installed, skipping"
        return 0
    fi
    log "Installing Claude Code..."
    PATH="$HOME/.local/share/mise/shims:$PATH" npm install -g @anthropic-ai/claude-code
}

symlink() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        warn "Backing up existing $(basename "$dst") → ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi
    ln -sfn "$src" "$dst"
    log "  $dst -> $src"
}

# アプリ自身が state を書き込む設定ディレクトリ。丸ごと symlink すると repo に
# state が漏れる(例: zsh が ZDOTDIR に書く .zcompdump)ため、中身をファイル単位でリンクする。
FILE_LINK_DIRS="zsh"

# ディレクトリ内の全ファイルを構造を保ったまま個別 symlink する(repo に無い state ファイルには触れない)。
link_dir_contents() {
    local srcdir="$1" dstdir="$2" f rel
    [ -L "$dstdir" ] && rm -f "$dstdir"   # 旧: dir 全体が symlink だった場合は実 dir に戻す
    mkdir -p "$dstdir"
    while IFS= read -r f; do
        rel="${f#"$srcdir"/}"
        symlink "$f" "$dstdir/$rel"
    done < <(find "$srcdir" \( -type f -o -type l \))
}

# .config/ 直下のエントリを $HOME/.config/ へリンクする。原則ディレクトリごと symlink
# (新しい設定はファイルを足すだけで反映)。ただし FILE_LINK_DIRS のものはファイル単位でリンクする。
create_symlinks() {
    log "Creating symlinks..."
    symlink "$DOTFILES_DIR/.zshenv" "$HOME/.zshenv"
    local src name
    for src in "$DOTFILES_DIR"/.config/*; do
        [ -e "$src" ] || continue
        name=$(basename "$src")
        case " $FILE_LINK_DIRS " in
            *" $name "*) link_dir_contents "$src" "$HOME/.config/$name" ;;
            *)           symlink "$src" "$HOME/.config/$name" ;;
        esac
    done
}

install_tools() {
    log "Installing tools via mise..."
    mise trust "$DOTFILES_DIR/.config/mise/config.toml"
    if ! mise plugins list | grep -q '^nim$'; then
        mise plugins install nim https://github.com/asdf-community/asdf-nim.git
    fi
    mise install
}

set_default_shell() {
    local zsh_path; zsh_path=$(which zsh)
    if [ "$SHELL" != "$zsh_path" ]; then
        log "Changing default shell to zsh..."
        if [ "$(id -u)" = "0" ]; then
            chsh -s "$zsh_path" root
        else
            chsh -s "$zsh_path"
        fi
    fi
}

main() {
    log "Starting dotfiles setup..."
    install_packages
    install_mise
    install_fzf
    install_omz
    install_starship
    install_rust
    install_gh
    create_symlinks
    install_tools
    install_claude_code
    set_default_shell
    log "Setup complete! Run: exec zsh"
}

main "$@"
