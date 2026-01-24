# Linux Home Manager configuration (minimal, for Spark containers)
{ config, pkgs, lib, self, isDarwin, isLinux, ... }:

{
  imports = [
    ../home/shell.nix
    ../home/git.nix
    ../home/programs/neovim.nix
    ../home/programs/starship.nix
  ];

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # XDG directories
  xdg = {
    enable = true;
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    cacheHome = "${config.home.homeDirectory}/.cache";
  };

  # Link config files
  xdg.configFile = {
    "nvim" = {
      source = ../../config/nvim;
      recursive = true;
    };
    "zellij" = {
      source = ../../config/zellij;
      recursive = true;
    };
    "atuin" = {
      source = ../../config/atuin;
      recursive = true;
    };
  };

  # Session variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
    BAT_THEME = "base16";
  };

  # Minimal package set for Linux containers
  home.packages = with pkgs; [
    # Custom Go tools from this repo
    self.packages.${pkgs.system}.dotfiles-tools

    # Core tools
    git
    gh
    neovim
    ripgrep
    fzf
    bat
    jq
    yq
    tree
    curl
    wget

    # Development
    go
    gopls
    nodejs_22
    python311

    # Kubernetes
    kubectl
    kubernetes-helm
    k9s

    # Terminal
    starship
    zellij
    atuin
    lazygit

    # Networking
    iproute2
  ];
}
