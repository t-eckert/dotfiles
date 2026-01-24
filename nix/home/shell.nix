# Zsh shell configuration (fully declarative, replaces .zshrc)
{ config, pkgs, lib, isDarwin, ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    # History configuration
    history = {
      size = 10000;
      save = 20000;
      path = "${config.home.homeDirectory}/.zsh_history";
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      extended = true;
      share = true;
    };

    # Shell aliases
    shellAliases = {
      # Kubernetes
      k = "kubectl";
      kbb = "kubectl run -i --tty --rm debug --image=busybox --restart=Never -- sh";

      # Editor
      v = "nvim";
      zrc = "$EDITOR ~/.config/home-manager/home.nix";  # Edit home-manager config

      # Terminal tools
      z = "zellij";
      cat = "bat";
      tree = "tree --dirsfirst";

      # Python
      py = "python3";
      python = "python3";
      venv = "source .venv/bin/activate";

      # Directories
      md = "mkdir";
      mdcd = "mkdir $_ && cd $_";

      # Git
      gs = "git status";

      # Docker
      dockert = "docker";  # Typo alias

      # Common typos
      clera = "clear";

      # File operations
      mvlatest = ''mv "$(ls -t ~/Downloads/* | head -n1)" .'';
    };

    # Oh My Zsh configuration
    oh-my-zsh = {
      enable = true;
      plugins = [
        "1password"
        "aliases"
        "docker"
        "git"
        "git-auto-fetch"
        "gitignore"
        "gh"
        "golang"
        "helm"
        "kubectl"
        "node"
        "python"
        "web-search"
      ];
      # Disable theme since we use Starship
      theme = "";
    };

    # Session variables
    sessionVariables = {
      GOPATH = "${config.home.homeDirectory}/go";
      FZF_DEFAULT_COMMAND = "rg --files --hidden --follow --glob '!.git/'";
      FZF_CTRL_T_COMMAND = "rg --files --hidden --follow --glob '!.git/'";
      NVM_DIR = "${config.home.homeDirectory}/.nvm";
      LS_COLORS = "no=0;97:fi=0;34:di=1;97:ln=1;97:pi=0;32:ex=1;35:ow=1;97";
    };

    # Extra initialization (runs at the end of .zshrc)
    initExtra = ''
      # Disable command correction (keep auto-suggestions but not corrections)
      unsetopt correct_all

      # Vi mode
      bindkey -v
      autoload -z edit-command-line
      zle -N edit-command-line
      bindkey -M vicmd v edit-command-line

      # Lazy load kubectl completion for faster shell startup
      if [[ $commands[kubectl] ]]; then
        kubectl() {
          if ! type __start_kubectl >/dev/null 2>&1; then
            source <(command kubectl completion zsh)
          fi
          command kubectl "$@"
        }
      fi

      # FZF key bindings if available
      [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

      # NVM (if installed outside of Nix)
      [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

      # Google Cloud SDK (check multiple possible locations)
      for gcloud_path in "$HOME/google-cloud-sdk" "$HOME/Downloads/google-cloud-sdk" "/usr/local/Caskroom/google-cloud-sdk"; do
        if [ -f "$gcloud_path/path.zsh.inc" ]; then
          source "$gcloud_path/path.zsh.inc"
          [ -f "$gcloud_path/completion.zsh.inc" ] && source "$gcloud_path/completion.zsh.inc"
          break
        fi
      done

      # Bun completions (if installed outside of Nix)
      [ -s "${config.home.homeDirectory}/.bun/_bun" ] && source "${config.home.homeDirectory}/.bun/_bun"

      # Homebrew (macOS)
      ${lib.optionalString isDarwin ''
      [ -d "/opt/homebrew/bin" ] && export PATH="/opt/homebrew/bin:$PATH"
      ''}
    '';

    # Profile extra (runs at login)
    profileExtra = ''
      # Add custom paths
      export PATH="${config.home.homeDirectory}/.local/bin:$PATH"
      export PATH="${config.home.homeDirectory}/go/bin:$PATH"

      # Bun
      export BUN_INSTALL="${config.home.homeDirectory}/.bun"
      export PATH="$BUN_INSTALL/bin:$PATH"
    '';
  };

  # FZF integration
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "rg --files --hidden --follow --glob '!.git/'";
    defaultOptions = [ "--height=40%" "--layout=reverse" "--border" ];
  };

  # Atuin shell history
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      search_mode = "fuzzy";
      filter_mode = "global";
      style = "compact";
    };
  };

  # Bat (cat replacement)
  programs.bat = {
    enable = true;
    config = {
      theme = "base16";
    };
  };

  # Direnv for per-project environments
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
