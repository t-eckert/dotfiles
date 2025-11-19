#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Backup directory with timestamp
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# Logging functions
log_info() {
	echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
	echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

# Backup function
backup_file() {
	local file=$1
	if [ -e "$file" ]; then
		mkdir -p "$BACKUP_DIR"
		log_info "Backing up $file to $BACKUP_DIR"
		cp -r "$file" "$BACKUP_DIR/"
	fi
}

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

# Install all packages from the Brewfile in the current directory
if [ -f "./Brewfile" ]; then
	log_info "Installing packages from Brewfile..."
	brew bundle --file="./Brewfile"
else
	log_warn "No Brewfile found in the current directory."
fi

# Create directories in ~/.config and symlink them using stow
CONFIG_DIR="./config"
if [ -d "$CONFIG_DIR" ]; then
	log_info "Setting up config directories..."

	cd "$CONFIG_DIR" || exit

	for dir in *; do
		if [ -d "$dir" ]; then
			if [ "$dir" = "hammerspoon" ]; then
				# Hammerspoon config goes to ~/.hammerspoon
				target_dir="$HOME/.hammerspoon"
				backup_file "$target_dir"
				log_info "Creating directory $target_dir"
				mkdir -p "$target_dir"
				log_info "Symlinking Hammerspoon config using stow..."
				stow -vt "$target_dir" "$dir" 2>&1 | grep -v "BUG in find_stowed_path" || true
			else
				# Other configs go to ~/.config
				target_dir="$HOME/.config/$(basename "$dir")"
				backup_file "$target_dir"
				log_info "Creating directory $target_dir"
				mkdir -p "$target_dir"
				log_info "Symlinking $dir using stow..."
				stow -vt "$target_dir" "$dir" 2>&1 | grep -v "BUG in find_stowed_path" || true
			fi
		fi
	done

	cd - >/dev/null || exit
else
	log_warn "No ./config directory found."
fi

# Symlink .zshrc to the home directory
if [ -f ".zshrc" ]; then
	backup_file "$HOME/.zshrc"
	log_info "Symlinking .zshrc to home directory..."
	ln -sf "$PWD/.zshrc" "$HOME/.zshrc"
else
	log_warn ".zshrc not found in dotfiles directory"
fi

# Symlink .gitconfig to the home directory
if [ -f ".gitconfig" ]; then
	backup_file "$HOME/.gitconfig"
	log_info "Symlinking .gitconfig to home directory..."
	ln -sf "$PWD/.gitconfig" "$HOME/.gitconfig"
else
	log_warn ".gitconfig not found in dotfiles directory"
fi

# Symlink .editorconfig to the home directory
if [ -f ".editorconfig" ]; then
	backup_file "$HOME/.editorconfig"
	log_info "Symlinking .editorconfig to home directory..."
	ln -sf "$PWD/.editorconfig" "$HOME/.editorconfig"
else
	log_warn ".editorconfig not found in dotfiles directory"
fi

# Install tools
if command -v go &>/dev/null; then
	log_info "Installing Go tools..."
	go install ./tools/*
else
	log_error "Go is not installed. Skipping Go tools installation."
fi

log_info "Installation complete!"
if [ -d "$BACKUP_DIR" ]; then
	log_info "Backups saved to: $BACKUP_DIR"
fi
