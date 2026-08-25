# Package list
{ config, pkgs, lib, self, hunk, isDarwin, isLinux, ... }:

let
  # Platform-specific packages
  darwinPackages = with pkgs; [
    iproute2mac      # macOS networking tools
    libiconv         # Required for Rust linking on macOS
    # NOTE: gcc is deliberately NOT installed on macOS. It puts a `cc` and an `ld`
    # on PATH ahead of /usr/bin, and both break native builds:
    #   - its `cc` has no macOS SDK, so any C dep that includes a system framework
    #     header (e.g. libusb1-sys -> IOKit/IOTypes.h) fails to compile
    #   - its `ld` (cctools-binutils-darwin-wrapper, pulled in by the gcc wrapper)
    #     emits unwind tables the macOS unwinder can't walk, so every Rust panic
    #     aborts with "failed to initiate panic, error 5" instead of unwinding
    # Apple's clang at /usr/bin/cc is the correct native toolchain here. If a
    # project genuinely needs GCC, scope it into that project's devshell.
  ];

  linuxPackages = with pkgs; [
    iproute2         # Linux networking tools
    gcc              # Native compiler on Linux; on macOS use Apple clang (see above)
  ];

  # Custom Go tools from this repo
  dotfiles-tools = self.packages.${pkgs.stdenv.hostPlatform.system}.dotfiles-tools;

  # mq - jq for Markdown, built from source (not in nixpkgs)
  mq = self.packages.${pkgs.stdenv.hostPlatform.system}.mq;

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
    mq                      # jq for Markdown
    tree
    watch
    wget
    curl
    hunk.packages.${pkgs.stdenv.hostPlatform.system}.default

    # ============================================================
    # Languages & Runtimes
    # ============================================================
    # NOTE: mise is configured in shell.nix (programs.mise) rather than listed
    # here -- it needs the zsh integration to actually select pinned versions.
    # The versions below are the fallback for repos that pin nothing.

    # Go
    go
    gopls
    golangci-lint
    delve
    gotools                 # goimports and friends (golang.org/x/tools)
    gofumpt                 # stricter gofmt
    go-tools                # staticcheck suite (honnef.co/go/tools)

    # Node.js
    bun
    nodejs_22
    yarn
    pnpm
    (lib.hiPrio typescript) # higher priority to win over wrangler's bundled tsc
    typescript-language-server

    # Python (only one version to avoid conflicts)
    python311
    virtualenv

    # Deno
    deno

    # Rust
    rustup
    cargo-edit
    cargo-outdated

    # ============================================================
    # Cloud & Infrastructure
    # ============================================================
    # Kubernetes
    kubectl
    (kubernetes-helm.overrideAttrs (_: { doCheck = false; }))
    k9s
    kind
    kustomize
    fluxcd
    tilt                    # Runs the hound dev stack locally (Tiltfile at repo root)

    # Cloud CLIs
    azure-cli
    doctl                   # DigitalOcean
    flyctl                  # Fly.io
    awscli2
    # wrangler             # Cloudflare Workers — broken in nixpkgs (EBADF build failure), use `npx wrangler`

    # Speedtest CLI
    ookla-speedtest

    # HashiCorp
    terraform
    consul

    # Containers
    docker-client
    podman

    # ============================================================
    # Databases & Data
    # ============================================================
    postgresql_15
    mysql84                 # Client for hound's local DBs; Tilt runs the server, don't start it yourself

    # ============================================================
    # Protocol Buffers & APIs
    # ============================================================
    protobuf
    buf

    # ============================================================
    # Build tools
    # ============================================================
    go-task                 # Task runner (Taskfile)
    process-compose         # Process orchestration
    cmake
    ninja
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
    mosh                    # Roaming remote shell (client; servers use programs.mosh)

    # ============================================================
    # Networking & Security
    # ============================================================
    caddy                   # Web server
    nmap
    arp-scan
    nghttp2
    nss
    yubikey-manager         # ykman — configure/reset YubiKey applets

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
    typst                   # Document formatting
    presenterm              # Terminal slide decks from markdown

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

  # Note: casks (1password-cli, amethyst, macfuse) and select brews
  # (tailscale, redpanda) are managed by nix-darwin in darwin/default.nix
}
