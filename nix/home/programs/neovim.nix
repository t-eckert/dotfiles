# Neovim configuration
# Note: The actual Neovim config is kept in ./config/nvim/ and linked via
# xdg.configFile (see ../default.nix) as an out-of-store symlink so edits are
# live without a rebuild.
#
# We deliberately do NOT use `programs.neovim` here: recent home-manager always
# generates an init.lua and writes it into ~/.config/nvim. Since we symlink that
# whole directory out-of-store, home-manager fails with
# "Error installing file '.config/nvim/init.lua' outside $HOME".
# Installing neovim and its tooling as plain packages avoids that conflict.
{ config, pkgs, lib, ... }:

{
  # NOTE: gopls, lua-language-server, typescript-language-server and ripgrep are
  # NOT repeated here -- they are declared in packages.nix. Listing them twice was
  # harmless (same derivation) but meant two places to edit.
  home.packages = with pkgs; [
    neovim

    # Language servers
    nil                          # Nix LSP
    pyright                      # Python LSP

    # Formatters
    stylua                       # Lua formatter
    nixpkgs-fmt                  # Nix formatter
    prettier                     # JS/TS/JSON formatter

    # Linters
    shellcheck                   # Shell script linter

    # Tools used by plugins
    fd                           # For telescope
    tree-sitter                  # For treesitter
  ];

  # vi/vim aliases (previously provided by programs.neovim)
  home.shellAliases = {
    vi = "nvim";
    vim = "nvim";
  };
}
