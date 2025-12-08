#!/bin/bash
# Debian installation script for dotfiles
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
export PLATFORM="debian"

log_info "Starting Debian dotfiles installation..."

# Check prerequisites
check_prerequisites() {
	log_info "Checking prerequisites..."

	# Install core dependencies first
	local core_deps=("curl" "wget" "git" "sudo")
	local missing_deps=()

	for dep in "${core_deps[@]}"; do
		if ! command -v "$dep" &>/dev/null; then
			missing_deps+=("$dep")
		fi
	done

	if [ ${#missing_deps[@]} -gt 0 ]; then
		log_warn "Missing core dependencies: ${missing_deps[*]}"
		log_info "Installing core dependencies..."
		sudo apt-get update
		sudo apt-get install -y "${missing_deps[@]}"
	fi
}

# Check prerequisites
check_prerequisites

# Update package cache
pm_update

# Setup external repositories
if [ -f "$SCRIPT_DIR/packages/debian-external-repos.sh" ]; then
	log_info "Setting up external repositories..."
	source "$SCRIPT_DIR/packages/debian-external-repos.sh"
	setup_external_repos
else
	log_warn "External repos setup script not found, skipping..."
fi

# Install packages from manifest
if [ -f "$SCRIPT_DIR/packages/debian.manifest" ]; then
	pm_install_list "$SCRIPT_DIR/packages/debian.manifest"
else
	log_warn "Debian manifest not found"
fi

# Install external repo packages (now that repos are added)
log_info "Installing external repo packages..."
local external_packages=(
	"gh"
	"docker-ce"
	"docker-ce-cli"
	"containerd.io"
	"kubectl"
	"terraform"
	"helm"
	"nodejs"
	"npm"
	"tailscale"
)

for pkg in "${external_packages[@]}"; do
	if ! pm_is_installed "$pkg"; then
		pm_install "$pkg" || log_warn "Failed to install $pkg, continuing..."
	else
		log_info "$pkg is already installed"
	fi
done

# Install Oh My Zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
	log_info "Installing Oh My Zsh..."
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
	log_info "Oh My Zsh is already installed"
fi

# Install zsh-autosuggestions
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
	log_info "Installing zsh-autosuggestions..."
	git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
	log_info "zsh-autosuggestions is already installed"
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
	log_warn "Go is not installed. Skipping Go tools installation."
fi

# Set zsh as default shell if not already
if [ "$SHELL" != "$(which zsh)" ]; then
	log_info "Setting zsh as default shell..."
	chsh -s "$(which zsh)" || log_warn "Failed to set zsh as default shell. You may need to run: chsh -s \$(which zsh)"
fi

log_info "Installation complete!"
if [ -d "$BACKUP_DIR" ]; then
	log_info "Backups saved to: $BACKUP_DIR"
fi

log_info ""
log_info "Next steps:"
log_info "1. Restart your shell or run: exec zsh"
log_info "2. For Docker, add your user to docker group: sudo usermod -aG docker \$USER"
log_info "3. For Tailscale, start the service: sudo systemctl enable --now tailscaled"
