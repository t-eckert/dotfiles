# Home Manager configuration - base module
{ config, pkgs, lib, self, isDarwin, isLinux, ... }:

{
  imports = [
    ./packages.nix
    ./shell.nix
    ./git.nix
    ./ssh.nix
    ./programs/neovim.nix
    ./programs/starship.nix
  ];

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # State version (required)
  home.stateVersion = "24.05";

  # XDG directories
  xdg = {
    enable = true;
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    cacheHome = "${config.home.homeDirectory}/.cache";
  };

  # Link existing config files from ./config/ directory
  # These are files that are complex enough to keep as separate configs
  # Note: recursive = false means a single symlink to the directory
  # This prevents individual file symlinking and circular references
  xdg.configFile = {
    # Neovim configuration — out-of-store symlink so edits are live without rebuild
    "nvim".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/Repos/github.com/t-eckert/dotfiles/config/nvim";

    # Ghostty terminal configuration
    "ghostty" = {
      source = ../../config/ghostty;
      recursive = false;
    };

    # Zellij terminal multiplexer
    "zellij" = {
      source = ../../config/zellij;
      recursive = false;
    };

    # Atuin shell history
    "atuin" = {
      source = ../../config/atuin;
      recursive = false;
    };

    # k9s Kubernetes manager
    "k9s" = {
      source = ../../config/k9s;
      recursive = false;
    };

    # Helm configuration
    "helm" = {
      source = ../../config/helm;
      recursive = false;
    };

    # Note: gh config is managed by programs.gh in git.nix
    # hosts.yml must be writable for authentication, so we don't symlink it
  };

  # Home directory files
  home.file = {
    # EditorConfig
    ".editorconfig".source = ../../.editorconfig;
  } // lib.optionalAttrs isDarwin {
    # Hammerspoon (macOS only, uses ~/.hammerspoon not ~/.config)
    ".hammerspoon" = {
      source = ../../config/hammerspoon;
      recursive = true;
    };
  };

  # Session variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
    BAT_THEME = "base16";

    # skopeo (and podman's tooling) otherwise looks for registry credentials
    # under /run/containers/<uid>, which is root-owned 0700 on the NixOS box --
    # so every non-root `skopeo inspect` failed with a permission error before
    # it ever reached the network, even for a public image. Point it somewhere
    # the user owns. Harmless on macOS, where the path simply does not exist
    # until something writes it.
    REGISTRY_AUTH_FILE = "${config.home.homeDirectory}/.config/containers/auth.json";
  };

  # Session path additions
  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/go/bin"
    "/Applications/Tailscale.app/Contents/MacOS"
  ];
}
