# Debian Installation Guide

This guide explains how to install the dotfiles on a native Debian system (bare metal, VM, or WSL).

## Overview

The installation script automatically:
- Detects Debian as the platform
- Sets up external package repositories
- Installs packages from the Debian manifest
- Configures Zsh with Oh My Zsh
- Symlinks configuration files
- Installs Go tools
- Sets up platform-specific PATH configurations

## Prerequisites

- Debian 12 (Bookworm) or later
- `sudo` access
- Internet connection

## Quick Start

```bash
# Clone the repository
git clone https://github.com/t-eckert/dotfiles.git
cd dotfiles

# Run the installation script
./install.sh
```

The script will:
1. Detect that you're on Debian
2. Install core dependencies
3. Setup external repositories (GitHub CLI, Docker, etc.)
4. Install all packages
5. Configure your environment

## What Gets Installed

### Core Dependencies
- curl, wget, git, stow
- build-essential (gcc, make, etc.)
- gnupg2, ca-certificates

### Development Tools
- Neovim
- ripgrep (rg)
- fzf (fuzzy finder)
- bat (cat alternative)
- jq, yq (JSON/YAML processors)
- tree, nmap, watch

### Language Toolchains
- Go 1.24.0 (installed to `/usr/local/go`)
- Node.js LTS
- Python 3.11
- Rust (optional, via cargo)

### Container & Cloud Tools
- Docker CE
- kubectl (Kubernetes CLI)
- helm
- terraform
- GitHub CLI (gh)
- Azure CLI (optional)

### Shell Configuration
- Zsh
- Oh My Zsh
- zsh-autosuggestions plugin
- Custom .zshrc with platform-specific PATH

## Installation Details

### External Repositories

The installer adds these external repositories:

| Tool | Repository |
|------|------------|
| GitHub CLI | cli.github.com/packages |
| Docker | download.docker.com |
| Kubernetes | pkgs.k8s.io |
| HashiCorp | apt.releases.hashicorp.com |
| Node.js | deb.nodesource.com |
| Helm | baltocdn.com/helm |
| Tailscale | pkgs.tailscale.com |

You can customize which repos are added by editing `packages/debian-external-repos.sh`.

### Package Installation Order

Packages are installed in this order:

1. **Core** - curl, wget, git, stow, build-essential
2. **Dev Tools** - neovim, ripgrep, fzf, bat, jq
3. **Languages** - golang-go, python3, nodejs
4. **External** - gh, docker-ce, kubectl, terraform, helm

See `packages/debian.manifest` for the full list.

### Configuration Files

These configs are symlinked to your home directory:

| Source | Destination | Notes |
|--------|-------------|-------|
| `.zshrc` | `~/.zshrc` | Platform-specific PATH sourced |
| `.gitconfig` | `~/.gitconfig` | Global git config |
| `.editorconfig` | `~/.editorconfig` | Editor settings |
| `config/nvim/` | `~/.config/nvim/` | Neovim configuration |
| `config/ghostty/` | `~/.config/ghostty/` | Ghostty terminal (Debian variant) |
| `config/zellij/` | `~/.config/zellij/` | Zellij multiplexer |
| `config/k9s/` | `~/.config/k9s/` | K9s config (with XDG paths) |
| `config/atuin/` | `~/.config/atuin/` | Atuin history sync |
| `config/gh/` | `~/.config/gh/` | GitHub CLI config |
| `config/helm/` | `~/.config/helm/` | Helm repositories |

**Note:** Hammerspoon config is skipped on Debian (MacOS-only).

### Platform-Specific Differences

#### vs MacOS:

- **Package Manager**: apt instead of Homebrew
- **PATH**: `/usr/local/go/bin` instead of `/opt/homebrew/bin`
- **Skipped Apps**: Hammerspoon, Amethyst (MacOS window managers)
- **Config Variants**: Ghostty uses Debian-specific config (no `macos-titlebar-style`)

## Post-Installation

### Set Zsh as Default Shell

The installer attempts to set Zsh as your default shell. If it fails:

```bash
chsh -s $(which zsh)
```

Then log out and log back in.

### Docker Configuration

Add your user to the docker group:

```bash
sudo usermod -aG docker $USER
```

Log out and back in for the change to take effect.

### Tailscale Setup

Start and enable Tailscale:

```bash
sudo systemctl enable --now tailscaled
sudo tailscale up
```

### Verify Installation

```bash
# Check Go tools are installed
which slug teamtime serve

# Check shell configuration
echo $SHELL  # Should be /usr/bin/zsh or /bin/zsh

# Check Go version
go version

# Check Node.js
node --version
npm --version

# Check Docker
docker --version

# Check Kubernetes tools
kubectl version --client
helm version
```

## Customization

### Adding Packages

Edit `packages/debian.manifest` and add package names:

```ini
[my-packages]
htop
ncdu
tmux
```

Then run:

```bash
sudo apt-get update
sudo apt-get install -y htop ncdu tmux
```

### Removing Packages

To skip certain package categories, comment them out in `debian.manifest` before installation:

```ini
# [container-cloud]
# docker-ce
# kubectl
```

### Custom External Repos

Edit `packages/debian-external-repos.sh` to add or remove repository setup functions.

## Troubleshooting

### Installation Fails on Package Not Found

**Problem:** Package not available in Debian repositories

**Solution:**
1. Check if the package name is different on Debian
2. Look up package in `packages/package-map.json`
3. Update manifest or install manually

### Permission Denied Errors

**Problem:** Script can't write to certain directories

**Solution:**
```bash
# Ensure you have sudo access
sudo -v

# Run the installer again
./install.sh
```

### External Repository GPG Key Errors

**Problem:** GPG key verification fails

**Solution:**
```bash
# Clear old keys
sudo rm -rf /usr/share/keyrings/*

# Run installer again (it will re-add keys)
./install.sh
```

### Zsh Not Set as Default

**Problem:** Shell is still bash after installation

**Solution:**
```bash
# Manually set zsh as default
chsh -s $(which zsh)

# Log out and back in
```

### Go Tools Not Found

**Problem:** `slug`, `teamtime`, etc. not in PATH

**Solution:**
```bash
# Check GOPATH
echo $GOPATH

# Ensure Go bin is in PATH
export PATH=$HOME/go/bin:$PATH

# Reinstall tools
cd ~/dotfiles
go install ./tools/*
```

### Config Files Not Symlinked

**Problem:** Neovim or other configs not loading

**Solution:**
```bash
# Check symlinks
ls -la ~/.config/nvim

# Re-run config setup
cd ~/dotfiles
source lib/logger.sh
source lib/platform-detect.sh
source lib/config-manager.sh
export PLATFORM=debian
export DOTFILES_ROOT=$(pwd)
setup_configs
```

## Uninstallation

To remove dotfiles:

```bash
# Remove symlinks
rm ~/.zshrc ~/.gitconfig ~/.editorconfig
rm -rf ~/.config/nvim ~/.config/ghostty ~/.config/zellij ~/.config/k9s

# Remove Oh My Zsh
rm -rf ~/.oh-my-zsh

# Optionally remove installed packages
sudo apt-get remove --purge gh docker-ce kubectl terraform helm nodejs
```

Backups are saved to `~/.dotfiles-backup-YYYYMMDD-HHMMSS` during installation.

## Differences from Container Installation

| Aspect | Native Debian | Container |
|--------|---------------|-----------|
| Persistence | Everything persists | Only volumes persist |
| System Impact | Modifies system | Isolated environment |
| Performance | Native speed | Slight overhead |
| Flexibility | Full system access | Sandboxed |
| Use Case | Primary workstation | Development/CI |

See [CONTAINER.md](./CONTAINER.md) for containerized installation.

## Updates

To update dotfiles:

```bash
cd ~/dotfiles
git pull origin main
./install.sh
```

The installer will:
- Back up existing configs
- Update symlinks
- Reinstall Go tools
- Update shell configuration

## References

- [install-debian.sh](../install-debian.sh) - Debian installation script
- [packages/debian.manifest](../packages/debian.manifest) - Package list
- [packages/debian-external-repos.sh](../packages/debian-external-repos.sh) - External repositories
- [CONTAINER.md](./CONTAINER.md) - Container usage guide
