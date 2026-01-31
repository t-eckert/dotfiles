# macOS system configuration (nix-darwin)
{ config, pkgs, lib, self, username, ... }:

{
  # Primary user (required for user-specific settings like system.defaults)
  system.primaryUser = username;

  # Disable nix-darwin's Nix management (Determinate Systems installer handles this)
  nix.enable = false;

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
      }
    ];

    # Casks (GUI apps that must stay in Homebrew)
    casks = [
      "1password-cli"
      "amethyst"
    ];
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
        TrackpadThreeFingerDrag = false;  # Disable three-finger drag to enable swipe gestures
        TrackpadThreeFingerHorizSwipeGesture = 2;  # Three-finger swipe between spaces/desktops
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

  # Security - Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Fonts (optional)
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
  ];
}
