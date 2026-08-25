# macOS system configuration (nix-darwin)
{ config, pkgs, lib, self, username, hostName ? null, ... }:

{
  # Primary user (required for user-specific settings like system.defaults)
  system.primaryUser = username;

  # Machine name, declared here so macOS and the flake stay in agreement.
  #
  # `darwin-rebuild --flake .` resolves `darwinConfigurations.$(hostname -s)`.
  # macOS picks that name from the account's full name at setup time, which is
  # how the work Mac ended up as "Thomass-MacBook-Pro" while the personal one is
  # "Thomas-MacBook-Pro". Setting it here makes the name a declared fact rather
  # than an accident of the setup assistant, so a rebuild can never drift out
  # from under the flake.
  #
  # All three options accept null, and nix-darwin's activation script skips any
  # that are null -- so the `default` config (hostName = null) leaves whatever
  # name the machine already has untouched.
  networking = {
    computerName = hostName;   # Finder, AirDrop, Sharing pane
    hostName = hostName;       # what `hostname -s` returns
    localHostName = hostName;  # Bonjour / .local name
  };

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
    #
    # NOTE: cleanup = "zap" above means ANYTHING installed with `brew install`
    # and not listed here is removed on the next rebuild. If you brew-install
    # something you intend to keep, add it here in the same sitting.
    brews = [
      {
        name = "redpanda-data/tap/redpanda";
      }
      {
        # Required by the rtl_* SDR tools in /opt/homebrew/bin, which are built
        # from source and link against /opt/homebrew/opt/libusb/lib/libusb-1.0.0.dylib.
        # Without it every rtl_* command dies with a dyld "Library not loaded" error.
        name = "libusb";
      }
    ];

    # Casks (GUI apps that must stay in Homebrew)
    casks = [
      "1password-cli"
      "amethyst"
      "macfuse"
      "orbstack"      # Container runtime + Docker daemon; Tilt/hound need a live daemon
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
        Clicking = false;
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
