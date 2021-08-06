#!/usr/bin/env bash

DOTFILES="$(pwd)"

# Replace .zshrc with dotfiles .zshrc
target="$HOME/.zshrc"
projectile="$DOTFILES/zsh/.zshrc"
if [ -e "$target" ]; then 
    read -p "Are you sure you want to overwrite .zshrc? " -n 1 -r; echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
    fi
    rm "$target"
fi
cp "$projectile" "$target"
