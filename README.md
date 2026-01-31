# Thomas Eckert's Dotfiles

This repository helps me unify development environments between multiple MacOS systems. It contains configuration files for applications I use and small sharp tools I've written to make my work more effective.

## Installation

Clone the repository and run `./install.sh`. The installer supports two methods:

- **Nix (recommended)**: Declarative, reproducible environment with nix-darwin
- **Legacy**: Traditional Homebrew + stow approach

### Nix Installation

```bash
./install.sh --nix
```

This will:
1. Install Nix via Determinate Systems installer
2. Configure your user as a trusted user (no more sudo for nix commands!)
3. Set up nix-darwin for macOS system configuration
4. Apply Home Manager for user environment

After installation, apply the full configuration:

```bash
# First time: Bootstrap nix-darwin
nix run nix-darwin -- switch --flake .

# Subsequent updates:
darwin-rebuild switch --flake .
# Or use the alias: reload-nix
```

### Nix Troubleshooting

**If nix commands require sudo:**

The installer automatically configures trusted users, but if you need to do it manually:

```bash
# Add yourself to trusted users
sudo tee -a /etc/nix/nix.custom.conf > /dev/null <<EOF

# Allow user to run nix commands without sudo
trusted-users = root $(whoami)
EOF

# Restart the nix daemon
sudo launchctl kickstart -k system/systems.determinate.nix-daemon

# Verify you're trusted
nix store ping  # Should show "Trusted: 1"
```

## Configs

- [Atuin](./config/atuin)
- [GitHub CLI](./config/gh)
- [Ghostty](./config/ghostty)
- [Helm](./config/helm)
- [K9s](./config/k9s)
- [Neovim](./config/nvim)
- [Zellij](./config/zellij)

## Tools

I've unified my tooling around simple Go applications. They are all available in [`tools`](./tools). The install script 

- [`create-react-component`](./tools/create-react-component) generates a new React component with the given name.
- [`fetch-gitignore`](./tools/fetch-gitignore) fetches a `.gitignore` file from the GitHub gitignore repository.
- [`normalize-lines`](./tools/normalize-lines) normalizes lines in a string of text to be 80 characters long without breaking words.
- [`prepend`](./tools/prepend) a file renaming tool which will prepend a given string to a glob.
- [`serve`](./tools/serve) serve the current directory as a file server.
- [`slug`](./tools/slug) 
- [`teamtime`](./tools/teamtime) tells you what time is is for everyone on your team.
