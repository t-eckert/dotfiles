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

      # Core settings
      core = {
        editor = "nvim";
        autocrlf = "input";
        whitespace = "trailing-space,space-before-tab";
        fsmonitor = true;
        untrackedCache = true;
      };

      # Default branch
      init.defaultBranch = "main";

      # Pull behavior
      pull.rebase = true;

      # Push behavior
      push = {
        default = "current";
        autoSetupRemote = true;
        followTags = true;
      };

      # Fetch behavior
      fetch = {
        prune = true;
        pruneTags = true;
      };

      # Rebase behavior
      rebase = {
        autoStash = true;
        autoSquash = true;
      };

      # Diff and merge
      merge = {
        conflictStyle = "zdiff3";
        ff = false;
      };
      diff = {
        algorithm = "histogram";
        colorMoved = "default";
      };

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
      color.ui = "auto";

      # Help
      help.autocorrect = 1;

      # Aliases
      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        unstage = "reset HEAD --";
        last = "log -1 HEAD --stat";
        lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        ll = "log --pretty=format:\"%C(yellow)%h%Cred%d\\ %Creset%s%Cblue\\ [%cn]\" --decorate --numstat";
        amend = "commit --amend --no-edit";
        undo = "reset --soft HEAD~1";
        wip = "!git add -A && git commit -m 'WIP'";
        aliases = "config --get-regexp alias";
        branches = "branch -a";
        tags = "tag -l";
        fb = "!f() { git branch -a --contains $1; }; f";
        fm = "!f() { git log --pretty=format:'%C(yellow)%h  %Cblue%ad  %Creset%s%Cgreen  [%cn] %Cred%d' --decorate --date=short --grep=$1; }; f";
        dm = "!git branch --merged | grep -v '\\\\*' | xargs -n 1 git branch -d";
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
