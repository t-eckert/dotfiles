#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

chmod 700 ~/.ssh 2>/dev/null || true
chmod 600 ~/.ssh/config 2>/dev/null || true

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

log_header() {
  echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"
}

# Show usage
show_usage() {
  echo "Usage: $0 [OPTION]"
  echo ""
  echo "Options:"
  echo "  --help      Show this help message"
}

# Install Nix using Determinate Systems installer
install_nix() {
  log_header "Installing Nix"

  if command -v nix &>/dev/null; then
    log_info "Nix is already installed."
    nix --version
    return 0
  fi

  log_info "Installing Nix via Determinate Systems installer..."
  log_info "This provides better macOS support and automatic flakes enablement."

  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

  # Source nix profile for current shell
  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi

  log_info "Nix installed successfully!"
}

# Configure Nix trusted users
configure_nix_trusted_users() {
  log_header "Configuring Nix Trusted Users"

  local nix_custom_conf="/etc/nix/nix.custom.conf"
  local current_user=$(whoami)

  # Check if already configured
  if grep -q "trusted-users.*$current_user" "$nix_custom_conf" 2>/dev/null; then
    log_info "User '$current_user' is already a trusted user."
    return 0
  fi

  log_info "Adding '$current_user' to Nix trusted users..."
  log_info "This allows running nix commands without sudo."

  # Add trusted-users configuration
  if sudo tee -a "$nix_custom_conf" > /dev/null <<EOF

# Allow user to run nix commands without sudo
trusted-users = root $current_user
EOF
  then
    log_info "Added trusted-users configuration to $nix_custom_conf"

    # Restart nix daemon to apply changes
    log_info "Restarting Nix daemon..."
    if sudo launchctl kickstart -k system/systems.determinate.nix-daemon 2>/dev/null; then
      log_info "Nix daemon restarted successfully."
    else
      log_warn "Could not restart Nix daemon automatically."
      log_warn "You may need to restart your system or run:"
      log_warn "  sudo launchctl kickstart -k system/systems.determinate.nix-daemon"
    fi

    # Verify configuration
    sleep 1
    if nix store ping 2>/dev/null | grep -q "Trusted: 1"; then
      log_info "Verified: You are now a trusted Nix user!"
    else
      log_warn "Unable to verify trusted user status immediately."
      log_warn "Try logging out and back in, or run: nix store ping"
    fi
  else
    log_error "Failed to configure trusted users."
    log_error "You may need to run this manually or restart the installation."
    return 1
  fi
}

# Install nix-darwin (macOS only)
install_nix_darwin() {
  if [[ "$(uname)" != "Darwin" ]]; then
    return 0
  fi

  log_header "Setting up nix-darwin"

  if command -v darwin-rebuild &>/dev/null; then
    log_info "nix-darwin is already installed."
    return 0
  fi

  log_info "nix-darwin will be bootstrapped on first activation."
  log_info "Run: nix run nix-darwin -- switch --flake ."
}

# Apply Nix configuration
apply_nix_config() {
  log_header "Applying Nix Configuration"

  # Detect system
  local system
  if [[ "$(uname)" == "Darwin" ]]; then
    if [[ "$(uname -m)" == "arm64" ]]; then
      system="aarch64-darwin"
    else
      system="x86_64-darwin"
    fi
  else
    system="x86_64-linux"
  fi

  log_info "Detected system: $system"

  # Build Go tools first to verify everything works
  log_info "Building Go tools with Nix..."
  if ! nix build .#dotfiles-tools --no-link; then
    log_warn "Go tools build failed. You may need to update the vendorHash in nix/packages/go-tools.nix"
    log_warn "Run: nix build .#dotfiles-tools 2>&1 | grep 'got:' to find the correct hash"
  fi

  # Apply configuration based on OS
  if [[ "$(uname)" == "Darwin" ]]; then
    log_info "To complete setup, run the following commands:"
    echo ""
    echo "  # First time: Bootstrap nix-darwin"
    echo "  nix run nix-darwin -- switch --flake ."
    echo ""
    echo "  # Subsequent updates:"
    echo "  darwin-rebuild switch --flake ."
    echo ""
    echo "  # Or just Home Manager (without system config):"
    echo "  nix run home-manager -- switch --flake .#thomaseckert@macos"
    echo ""
  else
    log_info "Applying Home Manager configuration..."
    nix run home-manager -- switch --flake ".#thomaseckert@linux"
  fi
}

# Main installation
main() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --help)
        show_usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
    esac
  done

  install_nix
  configure_nix_trusted_users
  install_nix_darwin
  apply_nix_config

  log_header "Installation Complete!"

  echo ""
  echo "Quick reference:"
  echo "  nix develop           # Enter dev shell"
  echo "  nix build             # Build Go tools"
  echo "  nix flake update      # Update all inputs"
  echo ""
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "  darwin-rebuild switch --flake .   # Apply full macOS config"
  fi
  echo "  home-manager switch --flake .     # Apply Home Manager config"
  echo ""
}

main "$@"
