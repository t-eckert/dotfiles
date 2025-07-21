{
  description = "Thomas Eckert's development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, darwin, home-manager }:
  let
    configuration = { pkgs, ... }: {
      # Core system packages
      environment.systemPackages = with pkgs; [
        # Development tools
        go
        nodejs
        yarn
        python311
        python310
        lua
        luarocks
        deno
        
        # CLI tools
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
        
        # Kubernetes/Cloud tools
        kubectl
        kubernetes-helm
        kind
        kustomize
        k9s
        terraform
        azure-cli
        
        # Network tools
        nmap
        arp-scan
        tailscale
        
        # Development infrastructure
        docker
        postgresql_14
        postgresql_15
        postgresql_17
        protobuf
        buf
        caddy
        
        # Build tools
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
        
        # Media/Graphics
        ffmpeg
        
        # Editors/IDEs
        neovim
        lua-language-server
        ctags
        
        # Virtualization
        qemu
        
        # Other utilities
        grip
        d2
        pngpaste
      ];

      # System configuration
      system.stateVersion = 4;
      services.nix-daemon.enable = true;
      nix.settings.experimental-features = "nix-command flakes";

      # Homebrew for macOS-specific apps
      homebrew = {
        enable = true;
        casks = [
          "1password-cli"
          "amethyst" 
          "wezterm"
        ];
        taps = [
          "fluxcd/tap"
          "hashicorp/tap"
          "jesseduffield/lazygit"
          "redpanda-data/tap"
          "supabase/tap"
        ];
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

      # Shell configuration
      programs.zsh.enable = true;
    };
  in
  {
    darwinConfigurations."$(hostname)" = darwin.lib.darwinSystem {
      modules = [ configuration ];
    };
  };
}