# Home Manager configuration - base module
{ config, pkgs, lib, self, isDarwin, isLinux, ... }:

{
  imports = [
    ./packages.nix
    ./shell.nix
    ./git.nix
    ./programs/neovim.nix
    ./programs/starship.nix
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

  # Link existing config files from ./config/ directory
  # These are files that are complex enough to keep as separate configs
  xdg.configFile = {
    # Neovim configuration (complex, keep separate)
    "nvim" = {
      source = ../../config/nvim;
      recursive = true;
    };

    # Ghostty terminal configuration
    "ghostty" = {
      source = ../../config/ghostty;
      recursive = true;
    };

    # Zellij terminal multiplexer
    "zellij" = {
      source = ../../config/zellij;
      recursive = true;
    };

    # Atuin shell history
    "atuin" = {
      source = ../../config/atuin;
      recursive = true;
    };

    # k9s Kubernetes manager
    "k9s" = {
      source = ../../config/k9s;
      recursive = true;
    };

    # Helm configuration
    "helm" = {
      source = ../../config/helm;
      recursive = true;
    };

    # GitHub CLI
    "gh" = {
      source = ../../config/gh;
      recursive = true;
    };
  };

  # Hammerspoon (macOS only, uses ~/.hammerspoon not ~/.config)
  home.file = lib.mkIf isDarwin {
    ".hammerspoon" = {
      source = ../../config/hammerspoon;
      recursive = true;
    };
  };

  # EditorConfig
  home.file.".editorconfig".source = ../../.editorconfig;

  # Session variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
    BAT_THEME = "base16";
  };

  # Session path additions
  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/go/bin"
  ];
}
