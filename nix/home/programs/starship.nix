# Starship prompt configuration
# Uses the TOML config file from config/starship.toml for the full Catppuccin theme
{ config, pkgs, lib, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    # Settings are defined in config/starship.toml (linked via xdg.configFile)
  };

  # Link the starship config from the config directory
  xdg.configFile."starship.toml".source = ../../../config/starship.toml;
}
