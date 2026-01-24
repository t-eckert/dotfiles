# macOS system configuration (nix-darwin)
{ config, pkgs, lib, self, username, ... }:

{
  # Nix settings
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-users = [ "root" username ];
    };

    # Garbage collection
    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 3; Minute = 15; };
      options = "--delete-older-than 30d";
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages (macOS-specific)
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
  ];

  # Homebrew integration for casks that don't have Nix equivalents
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";  # Remove formulae not in this config
      upgrade = true;
    };

    # Taps
    taps = [
      "homebrew/services"
      "redpanda-data/tap"
    ];

    # Formulae that don't work well with Nix on macOS
    brews = [
      "tailscale"        # Better to use Homebrew service management
      {
        name = "redpanda-data/tap/redpanda";
        # args = [];
      }
    ];

    # Casks (GUI apps that must stay in Homebrew)
    casks = [
      "1password-cli"
      "amethyst"
    ];
  };

  # Services
  services = {
    # Tailscale VPN (if not using Homebrew)
    # tailscale.enable = true;
  };

  # macOS system defaults
  system = {
    defaults = {
      # Dock settings
      dock = {
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.4;
        expose-animation-duration = 0.1;
        minimize-to-application = true;
        mru-spaces = false;
        orientation = "bottom";
        show-recents = false;
        tilesize = 48;
      };

      # Finder settings
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        CreateDesktop = false;  # No desktop icons
        FXDefaultSearchScope = "SCcf";  # Current folder
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "clmv";  # Column view
        QuitMenuItem = true;
        ShowPathbar = true;
        ShowStatusBar = true;
        _FXShowPosixPathInTitle = true;
      };

      # Global settings
      NSGlobalDomain = {
        # Keyboard
        AppleKeyboardUIMode = 3;  # Full keyboard access
        ApplePressAndHoldEnabled = false;  # Key repeat instead of accents
        InitialKeyRepeat = 15;
        KeyRepeat = 2;

        # Mouse/Trackpad
        AppleEnableMouseSwipeNavigateWithScrolls = true;
        AppleEnableSwipeNavigateWithScrolls = true;

        # UI
        AppleInterfaceStyle = "Dark";
        AppleShowAllExtensions = true;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;

        # Windows
        NSWindowResizeTime = 0.001;
        _HIHideMenuBar = false;
      };

      # Trackpad
      trackpad = {
        Clicking = true;
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = true;
      };

      # Menu bar clock
      menuExtraClock = {
        Show24Hour = true;
        ShowSeconds = false;
      };
    };

    # Keyboard settings
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };

    # System state version
    stateVersion = 5;
  };

  # Shell - set default shell to Zsh
  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];

  # Users
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };

  # Security
  security.pam.enableSudoTouchIdAuth = true;

  # Fonts (optional)
  fonts.packages = with pkgs; [
    (nerdfonts.override {
      fonts = [
        "JetBrainsMono"
        "FiraCode"
        "Hack"
      ];
    })
  ];
}
