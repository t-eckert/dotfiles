# Neovim configuration
# Note: The actual Neovim config is kept in ./config/nvim/ and linked via xdg.configFile
# This module handles the Neovim package and its dependencies
{ config, pkgs, lib, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # Extra packages available to Neovim (for plugins, LSPs, etc.)
    extraPackages = with pkgs; [
      # Language servers
      lua-language-server
      nodePackages.typescript-language-server
      gopls
      nil                          # Nix LSP
      pyright                      # Python LSP

      # Formatters
      stylua                       # Lua formatter
      nixpkgs-fmt                  # Nix formatter
      nodePackages.prettier        # JS/TS/JSON formatter

      # Linters
      shellcheck                   # Shell script linter

      # Tools used by plugins
      ripgrep                      # For telescope
      fd                           # For telescope
      tree-sitter                  # For treesitter
    ];

    # Don't manage Neovim config via Home Manager
    # We keep our custom config in ./config/nvim/ for portability
    # extraLuaConfig is left empty - config comes from xdg.configFile link
  };
}
