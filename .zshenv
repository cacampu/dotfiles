#!/bin/zsh
# This file is the entry point for Zsh, read before anything else.

# 1. Define where Zsh's own config files live
export ZDOTDIR="$HOME/.config/zsh"

# 2. Define where Oh My Zsh lives
export ZSH="$HOME/.local/share/oh-my-zsh"

# 3. Load the shared environment file (optional, but good practice)
if [ -f "$HOME/.config/shell/env" ]; then
    . "$HOME/.config/shell/env"
fi

