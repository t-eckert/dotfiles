#!/bin/bash
# Setup Claude Code commands in a project
# Usage: ./setup-project.sh [target-directory]

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Get target directory (default to current directory)
TARGET_DIR="${1:-.}"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_COMMANDS="$DOTFILES_DIR/.claude/commands"

# Validate source directory exists
if [ ! -d "$SOURCE_COMMANDS" ]; then
    log_warn "Source commands directory not found: $SOURCE_COMMANDS"
    exit 1
fi

# Create target .claude directory if it doesn't exist
mkdir -p "$TARGET_DIR/.claude"

log_info "Setting up Claude Code commands in $TARGET_DIR"

# Ask user for installation method
echo "How would you like to install the commands?"
echo "1) Symlink (shared - updates automatically)"
echo "2) Copy (independent - won't receive updates)"
read -p "Choice [1/2]: " choice

case $choice in
    1)
        # Symlink
        if [ -e "$TARGET_DIR/.claude/commands" ]; then
            log_warn "Commands already exist at $TARGET_DIR/.claude/commands"
            read -p "Remove and replace? [y/N]: " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                rm -rf "$TARGET_DIR/.claude/commands"
            else
                log_info "Skipping commands setup"
                exit 0
            fi
        fi

        log_info "Creating symlink to shared commands..."
        ln -s "$SOURCE_COMMANDS" "$TARGET_DIR/.claude/commands"
        log_info "Commands symlinked successfully"
        log_info "Changes to dotfiles commands will automatically appear in this project"
        ;;
    2)
        # Copy
        if [ -e "$TARGET_DIR/.claude/commands" ]; then
            log_warn "Commands already exist at $TARGET_DIR/.claude/commands"
            read -p "Overwrite? [y/N]: " confirm
            if [[ ! $confirm =~ ^[Yy]$ ]]; then
                log_info "Skipping commands setup"
                exit 0
            fi
        fi

        log_info "Copying commands to project..."
        cp -r "$SOURCE_COMMANDS" "$TARGET_DIR/.claude/commands"
        log_info "Commands copied successfully"
        log_info "These commands are independent and won't receive updates from dotfiles"
        ;;
    *)
        log_warn "Invalid choice"
        exit 1
        ;;
esac

# Show available commands
log_info "Available commands:"
for cmd in "$TARGET_DIR/.claude/commands"/*.md; do
    if [ -f "$cmd" ]; then
        echo "  /$(basename "$cmd" .md)"
    fi
done

log_info "Setup complete! Use these commands in Claude Code with /command-name"
