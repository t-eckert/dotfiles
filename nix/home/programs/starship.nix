# Starship prompt configuration
{ config, pkgs, lib, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      # Format string - customize prompt layout
      format = lib.concatStrings [
        "$directory"
        "$git_branch"
        "$git_status"
        "$kubernetes"
        "$terraform"
        "$golang"
        "$nodejs"
        "$python"
        "$rust"
        "$nix_shell"
        "$line_break"
        "$character"
      ];

      # Directory
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
        style = "bold blue";
      };

      # Git branch
      git_branch = {
        symbol = " ";
        style = "bold purple";
        truncation_length = 20;
      };

      # Git status
      git_status = {
        style = "bold yellow";
        conflicted = "!";
        ahead = "";
        behind = "";
        diverged = "";
        untracked = "?";
        stashed = "$";
        modified = "~";
        staged = "+";
        renamed = "";
        deleted = "-";
      };

      # Kubernetes
      kubernetes = {
        disabled = false;
        symbol = "󱃾 ";
        style = "bold cyan";
        format = "[$symbol$context( \\($namespace\\))]($style) ";
      };

      # Terraform
      terraform = {
        symbol = "󱁢 ";
        style = "bold 105";
      };

      # Languages
      golang = {
        symbol = " ";
        style = "bold cyan";
      };

      nodejs = {
        symbol = " ";
        style = "bold green";
      };

      python = {
        symbol = " ";
        style = "bold yellow";
      };

      rust = {
        symbol = " ";
        style = "bold red";
      };

      # Nix shell indicator
      nix_shell = {
        symbol = " ";
        style = "bold blue";
        format = "[$symbol$state]($style) ";
      };

      # Character (prompt symbol)
      character = {
        success_symbol = "[](bold green)";
        error_symbol = "[](bold red)";
        vimcmd_symbol = "[](bold green)";
      };

      # Time (disabled by default)
      time = {
        disabled = true;
        format = "[$time]($style) ";
        style = "bold dimmed white";
      };

      # Command duration
      cmd_duration = {
        min_time = 2000;
        format = "[$duration]($style) ";
        style = "bold yellow";
      };
    };
  };
}
