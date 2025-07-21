#!/bin/bash

set -e

echo "Installing Nix on macOS..."

# Install Nix using the Determinate Nix installer (recommended)
if ! command -v nix &>/dev/null; then
    echo "Installing Nix..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
else
    echo "Nix is already installed."
fi

# Source nix
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
    source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi

# Install nix-darwin
echo "Installing nix-darwin..."
nix run nix-darwin -- switch --flake .#$(hostname -s)

echo "Nix setup complete!"
echo ""
echo "Next steps:"
echo "1. Restart your terminal or source your shell profile"
echo "2. Run 'darwin-rebuild switch --flake .' to apply configuration changes"
echo "3. Use 'nix search nixpkgs <package>' to find packages"
echo "4. Edit flake.nix to add/remove packages"