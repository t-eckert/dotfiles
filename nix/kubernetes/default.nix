# Kubernetes tools volume derivation
# This creates a directory structure that can be copied to a PVC
# and mounted in Spark pods for instant access to all tools
{ lib, pkgs, dotfiles-tools, ... }:

let
  # Tools to include in the volume
  tools = with pkgs; [
    # Custom tools
    dotfiles-tools

    # Core CLI tools
    coreutils
    gnugrep
    gnused
    gawk
    findutils

    # Editor
    neovim

    # Shell
    zsh
    bash
    starship

    # Search & filter
    ripgrep
    fzf
    jq
    yq

    # File tools
    bat
    tree
    eza

    # Git
    git
    gh
    lazygit
    delta

    # Development
    go
    gopls
    nodejs_22
    python311
    rustup
    cargo-edit
    cargo-outdated

    # Kubernetes
    kubectl
    kubernetes-helm
    k9s
    kustomize

    # Networking
    curl
    wget

    # Cloud CLIs
    awscli2
    azure-cli
  ];

  # Config files to include
  configDir = ../../config;

in pkgs.buildEnv {
  name = "k8s-tools-volume";
  paths = tools;

  # Create a single /bin directory with all tools
  pathsToLink = [ "/bin" "/share" ];

  # Handle conflicts by picking the first one
  ignoreCollisions = true;

  # Post-build: create setup scripts and copy configs
  postBuild = ''
    mkdir -p $out/etc
    mkdir -p $out/config

    # Copy configuration files (follow symlinks to get real files)
    cp -rL ${configDir}/nvim $out/config/ 2>/dev/null || true
    cp -rL ${configDir}/zellij $out/config/ 2>/dev/null || true
    cp -rL ${configDir}/atuin $out/config/ 2>/dev/null || true
    cp -rL ${configDir}/k9s $out/config/ 2>/dev/null || true
    cp -L ${configDir}/starship.toml $out/config/ 2>/dev/null || true

    # Create an activation script that pods can source
    cat > $out/etc/activate.sh << 'SCRIPT'
#!/bin/bash
# Dotfiles Tools Activation Script
# Source this to set up the environment in Spark containers
# Usage: source /home/user/.local/activate.sh

# Determine the base directory (where this script lives)
TOOLS_BASE="$(cd "$(dirname "''${BASH_SOURCE[0]}")" && pwd)"

# Add tools to PATH
export PATH="''${TOOLS_BASE}/bin:''${PATH}"

# XDG Base Directories - point to our config
export XDG_CONFIG_HOME="''${TOOLS_BASE}/config"
export XDG_DATA_HOME="''${TOOLS_BASE}/share"
export XDG_CACHE_HOME="''${HOME}/.cache"

# Editor
export EDITOR="nvim"
export VISUAL="nvim"

# Tool-specific settings
export BAT_THEME="base16"
export STARSHIP_CONFIG="''${XDG_CONFIG_HOME}/starship.toml"

# Shell history (keep in user's home)
export HISTFILE="''${HOME}/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=10000

# Initialize starship if available
if command -v starship &> /dev/null; then
    eval "$(starship init bash 2>/dev/null || starship init zsh 2>/dev/null || true)"
fi

echo "Dotfiles tools activated. $(ls "''${TOOLS_BASE}/bin" 2>/dev/null | wc -l) tools available."
SCRIPT
    chmod +x $out/etc/activate.sh

    # Create a manifest of included tools
    cat > $out/etc/manifest.txt << EOF
# K8s Tools Volume Manifest
# https://github.com/t-eckert/dotfiles
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Tools included:
$(ls -1 $out/bin | sort)

# Configs included:
$(ls -1 $out/config)
EOF
  '';

  meta = {
    description = "Pre-built tools volume for Kubernetes Spark environments";
    homepage = "https://github.com/t-eckert/dotfiles";
  };
}
