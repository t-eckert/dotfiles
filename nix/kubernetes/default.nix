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

    # Search & filter
    ripgrep
    fzf
    jq
    yq

    # File tools
    bat
    tree

    # Git
    git
    gh
    lazygit

    # Development
    go
    gopls
    nodejs_22
    python311

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

in pkgs.buildEnv {
  name = "k8s-tools-volume";
  paths = tools;

  # Create a single /bin directory with all tools
  pathsToLink = [ "/bin" "/share" ];

  # Handle conflicts by picking the first one
  ignoreCollisions = true;

  # Post-build: create a setup script
  postBuild = ''
    mkdir -p $out/etc

    # Create an activation script that pods can source
    cat > $out/etc/activate.sh << 'SCRIPT'
    #!/bin/bash
    # Source this to set up the environment
    export PATH="/tools/bin:$PATH"
    export EDITOR="nvim"
    export VISUAL="nvim"

    # Shell history
    export HISTFILE="$HOME/.zsh_history"
    export HISTSIZE=10000
    export SAVEHIST=10000

    echo "Tools activated. $(ls /tools/bin | wc -l) tools available."
    SCRIPT
    chmod +x $out/etc/activate.sh

    # Create a manifest of included tools
    cat > $out/etc/manifest.txt << EOF
    # K8s Tools Volume Manifest
    # Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

    $(ls -1 $out/bin | sort)
    EOF
  '';

  meta = {
    description = "Pre-built tools volume for Kubernetes Spark environments";
    homepage = "https://github.com/t-eckert/dotfiles";
  };
}
