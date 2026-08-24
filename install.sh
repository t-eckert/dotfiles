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

# Make the Nix toolchain reachable in *this* shell.
#
# A fresh install puts `nix` behind the daemon profile, and once nix-darwin has
# switched at least once `darwin-rebuild` lives in /run/current-system/sw/bin.
# A login shell picks both up automatically, but this script runs before any of
# that is on PATH -- so source and extend it explicitly. Idempotent: safe to
# call repeatedly, which is how the later steps stay re-runnable.
ensure_nix_on_path() {
  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
  export PATH="/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$PATH"
}

# Install Homebrew (macOS only)
#
# nix/darwin/default.nix sets `homebrew.enable = true`, and nix-darwin's
# homebrew module refuses to activate without the `brew` binary already present:
#
#   error: Using the homebrew module requires homebrew installed, aborting activation
#
# nix-darwin manages the *contents* of the Brewfile, never Homebrew itself, so
# this has to happen before the first switch.
install_homebrew() {
  if [[ "$(uname)" != "Darwin" ]]; then
    return 0
  fi

  log_header "Installing Homebrew"

  # Apple Silicon installs to /opt/homebrew; Intel to /usr/local.
  local brew_prefix
  if [[ "$(uname -m)" == "arm64" ]]; then
    brew_prefix="/opt/homebrew"
  else
    brew_prefix="/usr/local"
  fi

  if [[ -x "${brew_prefix}/bin/brew" ]]; then
    log_info "Homebrew is already installed."
  else
    log_info "Homebrew is required by the nix-darwin homebrew module."
    log_info "Installing via the official installer (this will ask for sudo)..."

    # NONINTERACTIVE stops the installer from waiting on a RETURN keypress and
    # lets it pull the Xcode Command Line Tools on its own if they're missing.
    if ! NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
      log_error "Homebrew installation failed."
      log_error "Install it manually, then re-run this script:"
      log_error '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
      return 1
    fi
  fi

  # Put brew on PATH for the rest of this script. The interactive shell picks it
  # up from nix/home/shell.nix on the next login, but the nix-darwin activation
  # we're about to run needs to find it now.
  if [[ -x "${brew_prefix}/bin/brew" ]]; then
    eval "$("${brew_prefix}/bin/brew" shellenv)"
    log_info "Homebrew ready: $(brew --version | head -1)"
  else
    log_error "Expected brew at ${brew_prefix}/bin/brew but it isn't there."
    return 1
  fi
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
  local current_user
  current_user=$(whoami)

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

# Determine which darwinConfigurations attribute applies to this machine.
#
# `--flake .` resolves `darwinConfigurations.$(hostname -s)`, and macOS derives
# that name from the account's full name during setup, so it varies per machine
# ("Thomas-MacBook-Pro" vs "Thomass-MacBook-Pro"). Rather than assume, ask the
# flake which hostnames it knows about and fall back to the hostname-independent
# `default` attribute. Echoes the flake target to use, e.g. ".#Thomas-MacBook-Pro".
darwin_flake_target() {
  local host
  host="$(hostname -s)"

  local known
  known="$(nix eval --raw .#darwinConfigurations \
    --apply 'cfgs: builtins.concatStringsSep " " (builtins.attrNames cfgs)' \
    2>/dev/null || true)"

  if [[ -z "$known" ]]; then
    # Flake could not be evaluated; the bare hostname is the best guess.
    echo ".#${host}"
    return 0
  fi

  if [[ " $known " == *" $host "* ]]; then
    echo ".#${host}"
  else
    log_warn "This machine's hostname is '${host}', which the flake does not define." >&2
    log_warn "Known configurations: ${known}" >&2
    log_warn "Using '.#default' for now. To make '--flake .' work bare, add" >&2
    log_warn "'${host}' to darwinHosts in flake.nix and switch again." >&2
    echo ".#default"
  fi
}

# Report the nix-darwin state (macOS only). The actual switch happens in
# apply_nix_config; this just puts the toolchain on PATH and says what's next so
# a re-run reads clearly.
install_nix_darwin() {
  if [[ "$(uname)" != "Darwin" ]]; then
    return 0
  fi

  log_header "Setting up nix-darwin"
  ensure_nix_on_path

  if command -v darwin-rebuild &>/dev/null; then
    log_info "nix-darwin is already bootstrapped; the config will be re-applied below."
  else
    log_info "nix-darwin will be bootstrapped during 'Applying Nix Configuration'."
  fi
}

# Guarantee the Home Manager *file* generation is live for this user.
#
# nix-darwin runs Home Manager's activation through
# `launchctl asuser ... sudo -u <you> <activation>`, and that step is what writes
# ~/.zshrc and the ~/.config/* symlinks. On a fresh bootstrap it can quietly
# fail to link files (an in-the-way dotfile, or the user's launchd domain not
# being ready yet), leaving a machine with every *package* installed but none of
# the config -- the "my zshrc didn't get picked up" failure mode. Detect that
# and run the activation script the current system embeds, directly as the
# invoking user, which is the codepath that reliably links the files.
ensure_home_manager_activated() {
  [[ "$(uname)" == "Darwin" ]] || return 0

  if [[ -f "$HOME/.zshrc" ]]; then
    log_info "Home Manager files are active (~/.zshrc present)."
    return 0
  fi

  log_warn "Shell config (~/.zshrc) is missing after the switch -- Home Manager files didn't link."
  log_info "Running Home Manager activation directly as $(whoami)..."

  # The activation script is referenced by an absolute /nix/store path on the
  # `launchctl asuser` line of the freshly-linked /run/current-system/activate.
  local activation
  activation="$(grep -oE "/nix/store/[a-z0-9]+-activation-$(whoami)" \
    /run/current-system/activate 2>/dev/null | head -1 || true)"

  if [[ -z "$activation" || ! -x "$activation" ]]; then
    log_error "Couldn't locate the Home Manager activation script in /run/current-system/activate."
    log_error "Re-run the switch by hand: sudo darwin-rebuild switch --flake ."
    return 1
  fi

  "$activation"

  if [[ -f "$HOME/.zshrc" ]]; then
    log_info "Home Manager activation completed; ~/.zshrc is now in place."
  else
    log_error "Activation ran but ~/.zshrc still isn't present. Inspect the output above."
    return 1
  fi
}

# Apply Nix configuration -- this is the step that actually switches the machine.
apply_nix_config() {
  log_header "Applying Nix Configuration"

  ensure_nix_on_path

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

  # Build the Go tools first as a cheap smoke test of the flake. Non-fatal: a
  # stale vendorHash shouldn't block the whole machine from being configured.
  log_info "Building Go tools with Nix..."
  if ! nix build .#dotfiles-tools --no-link; then
    log_warn "Go tools build failed. You may need to update the vendorHash in nix/packages/go-tools.nix"
    log_warn "Run: nix build .#dotfiles-tools 2>&1 | grep 'got:' to find the correct hash"
  fi

  # Apply configuration based on OS
  if [[ "$(uname)" == "Darwin" ]]; then
    local target
    target="$(darwin_flake_target)"

    if command -v darwin-rebuild &>/dev/null; then
      # Machine has switched before. `darwin-rebuild switch` is idempotent --
      # Nix only rebuilds what changed -- and needs root.
      log_info "Applying macOS configuration: sudo darwin-rebuild switch --flake ${target}"
      sudo darwin-rebuild switch --flake "${target}"
    else
      # First activation on this machine. nix-darwin isn't on PATH yet, so run
      # it straight from the flake registry; it escalates to root on its own.
      log_info "Bootstrapping nix-darwin: nix run nix-darwin -- switch --flake ${target}"
      nix run nix-darwin -- switch --flake "${target}"
      ensure_nix_on_path
    fi

    # The switch above installs packages even when the per-user file activation
    # silently fails; this backstops that so the shell config always lands.
    ensure_home_manager_activated
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

  # Run from the repo root so every `.#...` flake reference resolves no matter
  # where the script was invoked from.
  cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  # Each step is idempotent: it checks the current state and no-ops if the work
  # is already done, so re-running install.sh is the normal way to converge a
  # machine after editing the flake.
  #
  # Homebrew first: the nix-darwin homebrew module aborts activation without it.
  install_homebrew
  install_nix
  configure_nix_trusted_users
  install_nix_darwin
  apply_nix_config

  log_header "Installation Complete!"

  echo ""
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "Your machine is configured. Open a new terminal to pick up the shell."
    echo ""
  fi
  echo "Quick reference:"
  echo "  reload-nix            # Re-apply after editing the flake (darwin-rebuild switch)"
  echo "  ./install.sh          # Re-run the full, idempotent setup"
  echo "  nix develop           # Enter dev shell"
  echo "  nix flake update      # Update all inputs"
  echo ""
}

main "$@"
