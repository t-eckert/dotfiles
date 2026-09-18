# macOS system configuration (nix-darwin)
{ config, pkgs, lib, self, username, hostName ? null
, brewPackage, homebrew-services, redpanda-tap, launchdarkly-tap, ... }:

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

  # Homebrew itself, pinned.
  #
  # The `homebrew` block below manages only the *contents* of the Brewfile; it
  # shells out to whatever `brew` is on the system. Installed by the official
  # curl|bash script, that binary self-updates on its own schedule, so the
  # Homebrew version was the one part of this machine Nix did not describe.
  # nix-homebrew owns /opt/homebrew, and flake.nix's `brew-src` tag decides the
  # version.
  #
  # nix-homebrew patches Library/Homebrew/cmd/update.sh to strip
  # HOMEBREW_REPOSITORY out of the self-update loop, so `brew update` can no
  # longer move Homebrew off the pin -- it is a real pin, not a default.
  nix-homebrew = {
    enable = true;
    user = username;

    # No Intel prefix on this machine: /usr/local/Homebrew does not exist, and
    # setting this would have nix-homebrew create and manage a second prefix.
    enableRosetta = false;

    # Adopt the existing installation instead of demanding a clean prefix.
    # This deletes the Homebrew *git repository* under /opt/homebrew (Nix now
    # supplies those files) while leaving installed formulae and casks in place.
    autoMigrate = true;

    # The pinned source. Without this, nix-homebrew falls back to the tag in its
    # own flake.lock, which would put the version in someone else's repo.
    package = brewPackage;

    # Taps come from flake inputs. Keys must be the on-disk repository name --
    # `homebrew/homebrew-services`, not the short `homebrew/services` form that
    # `brew tap` accepts -- because they become directory names under
    # $HOMEBREW_LIBRARY/Taps.
    taps = {
      "homebrew/homebrew-services" = homebrew-services;
      "redpanda-data/homebrew-tap" = redpanda-tap;
      "launchdarkly/homebrew-tap" = launchdarkly-tap;
    };

    # Fully declarative taps. Side effect worth knowing: this also exports
    # HOMEBREW_NO_AUTO_UPDATE=1, and `brew tap` stops working imperatively --
    # adding a tap is now an edit to flake.nix plus a rebuild.
    mutableTaps = false;

    # Report the pinned version from `brew --version`.
    #
    # nix-homebrew normally embeds the version by sed-ing `^HOMEBREW_VERSION=`
    # in Library/Homebrew/brew.sh. As of Homebrew 7.0.1 that assignment has
    # moved into utils/git.sh (`set-homebrew-version-from-git`), so the sed
    # silently matches nothing and brew falls back to reporting
    # ">=4.3.0 (shallow or no git repository)" -- the Nix store copy has no .git
    # for it to describe.
    #
    # That function only assigns when HOMEBREW_VERSION is empty, and returns
    # early when there is no git revision to find, so exporting it here wins.
    extraEnv = {
      HOMEBREW_VERSION = brewPackage.version;
    };

    # Non-official taps need explicit trust, which previously had to be applied
    # by hand and read from ~/.homebrew/trust.json. Declaring it here means a
    # fresh machine trusts the tap before the first `brew bundle` runs.
    #
    # Note: removing an entry here does NOT revoke it; use `brew untrust`.
    trust = {
      taps = [ "redpanda-data/tap" "launchdarkly/tap" ];
      formulae = [ "redpanda-data/tap/redpanda" "launchdarkly/tap/ldcli" ];
    };
  };

  # Homebrew integration for casks that don't have Nix equivalents
  homebrew = {
    enable = true;
    onActivation = {
      # Off deliberately: with the version pinned above there is nothing for
      # Homebrew to auto-update itself to, and mutableTaps = false already
      # exports HOMEBREW_NO_AUTO_UPDATE=1. Leaving this true would only be a
      # misleading claim about what a rebuild does.
      autoUpdate = false;
      cleanup = "zap";  # Remove formulae not in this config
      upgrade = true;   # Still upgrades formulae/casks, which resolve via the API
    };

    # Taps, kept in lockstep with nix-homebrew.taps so the Brewfile can never
    # ask for a tap the (now immutable) Taps directory does not provide.
    taps = builtins.attrNames config.nix-homebrew.taps;

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
      {
        # Installed by hand on 2026-09-16 and declared nowhere, so the next
        # rebuild would have zapped it. The tap is pinned above for the same
        # reason: mutableTaps = false means `brew tap` cannot put it back.
        name = "launchdarkly/tap/ldcli";
      }
    ];

    # Casks (GUI apps that must stay in Homebrew)
    #
    # ghostty/tailscale-app/obsidian were installed by hand and declared nowhere,
    # so a fresh machine got their configs (config/ghostty, home.sessionPath, the
    # `ob` alias) and none of the apps. `brew bundle` passes --adopt for casks, so
    # it takes over the existing /Applications copies instead of colliding.
    casks = [
      "1password-cli"
      "amethyst"
      "ghostty"       # Terminal; config/ghostty is deployed by home-manager
      "macfuse"
      # NOTE: the obsidian cask's `zap` stanza trashes
      # ~/Library/Application Support/obsidian, which holds the vault registry and
      # settings (the vaults themselves live in ~/Notebook, ~/Redpanda, etc. and are
      # untouched). With cleanup = "zap" above, REMOVING this line deletes that
      # registry -- take a copy first if you ever drop it.
      "obsidian"      # shell.nix puts its CLI on PATH and aliases `ob`
      "orbstack"      # Container runtime + Docker daemon; Tilt/hound need a live daemon
    ];

    # Tailscale is deliberately NOT a cask.
    #
    # The tailscale-app cask installs via a .pkg that runs scripts as root, and
    # against the existing hand-installed /Applications/Tailscale.app it failed:
    #   installer: The install failed. ... An error occurred while running scripts
    # Tailscale itself then reported a conflict between multiple installations.
    # It stays hand-managed; home.sessionPath still points at the app bundle.
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
