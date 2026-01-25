# Git configuration
{ config, pkgs, lib, ... }:

{
  programs.git = {
    enable = true;

    # Git settings (new unified format)
    settings = {
      # User identity
      user = {
        name = "Thomas Eckert";
        email = "thomas.james.eckert@gmail.com";
      };

      # Default branch
      init.defaultBranch = "main";

      # Pull behavior
      pull.rebase = true;

      # Push behavior
      push.autoSetupRemote = true;

      # Diff and merge
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";

      # Performance
      core.fsmonitor = true;
      core.untrackedCache = true;

      # Credential helper (macOS keychain)
      credential.helper = lib.mkIf pkgs.stdenv.isDarwin "osxkeychain";

      # URL rewrites
      url = {
        "git@github.com:" = {
          insteadOf = "https://github.com/";
        };
      };

      # Rerere (remember conflict resolutions)
      rerere.enabled = true;

      # Color
      color.ui = true;

      # Aliases
      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        lg = "log --oneline --graph --decorate";
        ll = "log --oneline -10";
        amend = "commit --amend --no-edit";
        undo = "reset --soft HEAD~1";
        wip = "!git add -A && git commit -m 'WIP'";
      };
    };

    # Ignore patterns (global)
    ignores = [
      # macOS
      ".DS_Store"
      ".AppleDouble"
      ".LSOverride"
      "._*"

      # Editors
      "*.swp"
      "*.swo"
      "*~"
      ".idea/"
      ".vscode/"
      "*.sublime-*"

      # Environment files
      ".env"
      ".env.local"
      ".env.*.local"

      # Dependencies
      "node_modules/"
      "__pycache__/"
      "*.pyc"
      ".venv/"
      "vendor/"

      # Build outputs
      "dist/"
      "build/"
      "*.egg-info/"

      # Nix
      "result"
      "result-*"
    ];
  };

  # Delta for better diffs (now separate from git)
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;
      line-numbers = true;
      syntax-theme = "base16";
    };
  };

  # GitHub CLI
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
    };
  };

  # Lazygit TUI
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        theme = {
          lightTheme = false;
        };
      };
      git = {
        paging = {
          colorArg = "always";
          pager = "delta --dark --paging=never";
        };
      };
    };
  };
}
