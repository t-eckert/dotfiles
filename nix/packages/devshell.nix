# Development shell with all tools
{ pkgs, ... }:

pkgs.mkShell {
  name = "dotfiles-dev";

  # Build dependencies for working on the dotfiles
  buildInputs = with pkgs; [
    # Nix tools
    nil                    # Nix LSP
    nixpkgs-fmt            # Nix formatter

    # Go development
    go
    gopls
    golangci-lint
    delve

    # General utilities
    git
    gh
  ];

  shellHook = ''
    echo "dotfiles development shell"
    echo "  - Go $(go version | cut -d' ' -f3)"
    echo "  - Run 'nix build' to build Go tools"
    echo "  - Run 'nix flake check' to validate flake"
  '';
}
