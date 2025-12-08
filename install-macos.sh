#!/bin/bash
# MacOS installation script for dotfiles
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_ROOT="$SCRIPT_DIR"

# Source shared libraries
source "$SCRIPT_DIR/lib/logger.sh"
source "$SCRIPT_DIR/lib/platform-detect.sh"
source "$SCRIPT_DIR/lib/package-manager.sh"
source "$SCRIPT_DIR/lib/config-manager.sh"

# Set platform
export PLATFORM="macos"

log_info "Starting MacOS dotfiles installation..."

# Check prerequisites
check_prerequisites() {
	log_info "Checking prerequisites..."

	local missing_deps=()

	if ! command -v stow &>/dev/null; then
		missing_deps+=("stow")
	fi

	if ! command -v go &>/dev/null; then
		missing_deps+=("go")
	fi

	if [ ${#missing_deps[@]} -gt 0 ]; then
		log_warn "Missing dependencies: ${missing_deps[*]}"
		log_info "These will be installed via Homebrew if available."
	fi
}

# Install Homebrew if not installed
if ! command -v brew &>/dev/null; then
	log_info "Homebrew not found. Installing..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
	log_info "Homebrew is already installed."
fi

# Check prerequisites
check_prerequisites

# Install all packages from the Brewfile
if [ -f "$DOTFILES_ROOT/Brewfile" ]; then
	log_info "Installing packages from Brewfile..."
	brew bundle --file="$DOTFILES_ROOT/Brewfile"
else
	log_warn "No Brewfile found"
fi

# Setup configs using shared config manager
setup_configs

# Symlink dotfiles
symlink_dotfile ".zshrc"
symlink_dotfile ".gitconfig"
symlink_dotfile ".editorconfig"

# Setup platform-specific zshrc.d
setup_zshrc_platform

# Install Go tools
if command -v go &>/dev/null; then
	log_info "Installing Go tools..."
	cd "$DOTFILES_ROOT" && go install ./tools/*
else
	log_error "Go is not installed. Skipping Go tools installation."
fi

log_info "Installation complete!"
if [ -d "$BACKUP_DIR" ]; then
	log_info "Backups saved to: $BACKUP_DIR"
fi
