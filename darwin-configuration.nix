{ config, pkgs, ... }:

{
  # Core development packages
  environment.systemPackages = with pkgs; [
    # Programming languages and runtimes
    go
    nodejs
    yarn
    python311
    python310
    lua
    luarocks
    deno
    
    # Essential CLI tools
    bat
    ripgrep
    fzf
    jq
    yq
    tree
    watch
    curl
    wget
    git
    gh
    atuin
    zellij
    stow
    rename
    
    # Kubernetes and cloud tools
    kubectl
    kubernetes-helm
    kind
    kustomize
    k9s
    terraform
    azure-cli
    
    # Network utilities
    nmap
    arp-scan
    tailscale
    
    # Containerization and databases
    docker
    postgresql_14
    postgresql_15
    postgresql_17
    protobuf
    buf
    caddy
    
    # Build and compilation tools
    cmake
    ninja
    autoconf
    autoconf-archive
    automake
    gcc
    llvm
    nasm
    pkgconf
    ccache
    
    # Media processing
    ffmpeg
    
    # Text editors and language servers
    neovim
    lua-language-server
    ctags
    
    # Documentation and utilities
    grip
    d2
  ];

  # Use a stable Nix version
  system.stateVersion = 4;

  # Enable the Nix daemon
  services.nix-daemon.enable = true;

  # Enable flakes and new nix command
  nix.settings.experimental-features = "nix-command flakes";

  # Enable zsh system-wide
  programs.zsh.enable = true;

  # Homebrew integration for macOS-specific packages
  homebrew = {
    enable = true;
    
    # GUI applications that work better through Homebrew
    casks = [
      "1password-cli"
      "amethyst"
      "wezterm"
    ];

    # Third-party taps for specialized tools
    taps = [
      "fluxcd/tap"
      "hashicorp/tap" 
      "jesseduffield/lazygit"
      "redpanda-data/tap"
      "supabase/tap"
    ];

    # Tools from third-party taps or not available in nixpkgs
    brews = [
      "fluxcd/tap/flux"
      "hashicorp/tap/consul-k8s"
      "jesseduffield/lazygit/lazygit"
      "redpanda-data/tap/redpanda"
      "supabase/tap/supabase"
      "tigris-cli"
      "turso"
      "sqld"
      "talosctl"
      "flyctl"
      "doctl"
      "uv"
      "pngpaste"
    ];
  };
}
