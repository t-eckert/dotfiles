# Package list (replaces Brewfile)
{ config, pkgs, lib, self, isDarwin, isLinux, ... }:

let
  # Platform-specific packages
  darwinPackages = with pkgs; [
    iproute2mac      # macOS networking tools
  ];

  linuxPackages = with pkgs; [
    iproute2         # Linux networking tools
  ];

  # Custom Go tools from this repo
  dotfiles-tools = self.packages.${pkgs.system}.dotfiles-tools;

in {
  home.packages = with pkgs; [
    # ============================================================
    # Custom tools from this repo
    # ============================================================
    dotfiles-tools

    # ============================================================
    # Core development tools
    # ============================================================
    git
    gh                      # GitHub CLI
    # neovim - managed by programs.neovim in neovim.nix
    ripgrep
    fzf
    bat
    jq
    yq
    tree
    watch
    wget
    curl

    # ============================================================
    # Languages & Runtimes
    # ============================================================
    # Go
    go
    gopls
    golangci-lint
    delve

    # Node.js
    nodejs_22
    yarn
    nodePackages.typescript
    nodePackages.typescript-language-server

    # Python (only one version to avoid conflicts)
    python311
    virtualenv

    # Deno
    deno

    # Rust (optional - uncomment if needed)
    # rustup

    # ============================================================
    # Cloud & Infrastructure
    # ============================================================
    # Kubernetes
    kubectl
    kubernetes-helm
    k9s
    kind
    kustomize
    fluxcd

    # Cloud CLIs
    azure-cli
    doctl                   # DigitalOcean
    flyctl                  # Fly.io
    awscli2

    # HashiCorp
    terraform
    consul

    # Containers
    docker-client

    # ============================================================
    # Databases & Data
    # ============================================================
    postgresql_15

    # ============================================================
    # Protocol Buffers & APIs
    # ============================================================
    protobuf
    buf

    # ============================================================
    # Build tools
    # ============================================================
    cmake
    ninja
    gcc
    autoconf
    automake
    ccache
    gnumake

    # ============================================================
    # Terminal & Shell
    # ============================================================
    starship                # Prompt
    zellij                  # Terminal multiplexer
    atuin                   # Shell history
    lazygit                 # Git TUI

    # ============================================================
    # Networking & Security
    # ============================================================
    nmap
    arp-scan
    nghttp2
    nss

    # ============================================================
    # Media & Documents
    # ============================================================
    ffmpeg

    # ============================================================
    # Utilities
    # ============================================================
    rename
    ctags
    d2                      # Diagramming

    # ============================================================
    # Language servers & dev tools
    # ============================================================
    lua-language-server
    luarocks

    # ============================================================
    # Third-party tools (check nixpkgs availability)
    # ============================================================
    supabase-cli            # Supabase

  ] ++ (if isDarwin then darwinPackages else linuxPackages);

  # Note: The following are handled by nix-darwin or kept in Homebrew:
  # - 1password-cli (cask - managed by nix-darwin homebrew module)
  # - amethyst (cask - managed by nix-darwin homebrew module)
  # - tailscale (service - managed by nix-darwin services)
  # - redpanda (may need overlay if not in nixpkgs)
}
