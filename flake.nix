{
  description = "Thomas Eckert's dotfiles";

  inputs = {
    # Core nixpkgs - using unstable for latest packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Home Manager for dotfile management
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-darwin for macOS system configuration
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Flake utilities
    flake-utils.url = "github:numtide/flake-utils";

    # Git diff viewer
    hunk.url = "github:modem-dev/hunk";
  };

  outputs = { self, nixpkgs, home-manager, darwin, flake-utils, hunk }:
    let
      # Supported systems
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];

      # Helper to generate attrs for each system
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Get pkgs for a specific system
      pkgsFor = system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # User configuration
      username = "thomaseckert";
      homeDirectory = system:
        if nixpkgs.lib.hasSuffix "darwin" system
        then "/Users/${username}"
        else "/home/${username}";

      # Hostnames that should receive the macOS system configuration.
      #
      # `darwin-rebuild switch --flake .` looks up
      # `darwinConfigurations.$(hostname -s)`. macOS derives that name from the
      # account's full name during setup, so it is NOT stable across machines --
      # one Mac ends up "Thomas-MacBook-Pro" and another "Thomass-MacBook-Pro".
      # Listing every name here means a bare `--flake .` works on all of them.
      darwinHosts = [
        "Thomas-MacBook-Pro"   # personal
        "Thomass-MacBook-Pro"  # work (macOS generated the possessive form)
      ];

      # Builds the macOS system configuration for a given hostname.
      #
      # `hostName = null` produces a config that leaves the machine's name
      # alone -- used by the `default` alias for machines not yet listed above.
      mkDarwinSystem = hostName: darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = {
          inherit self username hostName;
        };
        modules = [
          ./nix/darwin
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              extraSpecialArgs = {
                inherit self hunk;
                isDarwin = true;
                isLinux = false;
              };
              users.${username} = import ./nix/home;
            };
          }
        ];
      };

    in {
      # ============================================================
      # Packages - Go CLI tools
      # ============================================================
      packages = forAllSystems (system:
        let pkgs = pkgsFor system;
        in {
          # Individual tools
          dotfiles-tools = pkgs.callPackage ./nix/packages/go-tools.nix { };

          # mq - jq for Markdown (not yet in nixpkgs)
          mq = pkgs.callPackage ./nix/packages/mq.nix { };

          # rwx - RWX CI CLI (not in nixpkgs; prebuilt release binary)
          rwx = pkgs.callPackage ./nix/packages/rwx.nix { };

          # Default package
          default = self.packages.${system}.dotfiles-tools;

          # Kubernetes tools volume
          k8s-tools-volume = pkgs.callPackage ./nix/kubernetes/default.nix {
            inherit (self.packages.${system}) dotfiles-tools;
          };
        }
      );

      # ============================================================
      # Development Shell
      # ============================================================
      devShells = forAllSystems (system:
        let pkgs = pkgsFor system;
        in {
          default = pkgs.callPackage ./nix/packages/devshell.nix { };
        }
      );

      # ============================================================
      # Home Manager Configurations
      # ============================================================
      homeConfigurations = {
        # macOS configuration (full dev setup)
        "thomaseckert@macos" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor "aarch64-darwin";
          extraSpecialArgs = {
            inherit self hunk;
            isDarwin = true;
            isLinux = false;
          };
          modules = [
            ./nix/home
            {
              home = {
                username = username;
                homeDirectory = homeDirectory "aarch64-darwin";
                stateVersion = "24.05";
              };
            }
          ];
        };

        # Linux configuration (for Spark containers)
        "thomaseckert@linux" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor "x86_64-linux";
          extraSpecialArgs = {
            inherit self hunk;
            isDarwin = false;
            isLinux = true;
          };
          modules = [
            ./nix/linux
            {
              home = {
                username = username;
                homeDirectory = homeDirectory "x86_64-linux";
                stateVersion = "24.05";
              };
            }
          ];
        };
      };

      # ============================================================
      # Darwin (macOS) System Configurations
      # ============================================================
      # Every hostname in `darwinHosts` gets the same Apple Silicon config, and
      # each one pins its own machine name declaratively (see nix/darwin), so
      # after the first switch the machine and the flake agree.
      #
      # `default` is a hostname-independent escape hatch for a machine whose
      # name is not in the list yet:
      #
      #   sudo darwin-rebuild switch --flake .#default
      #
      # If the work and personal machines ever need to diverge, replace the
      # genAttrs line with explicit entries that pass different module lists.
      darwinConfigurations =
        nixpkgs.lib.genAttrs darwinHosts mkDarwinSystem
        // { default = mkDarwinSystem null; };

      # ============================================================
      # Flake checks
      # ============================================================
      checks = forAllSystems (system:
        let pkgs = pkgsFor system;
        in {
          # Verify Go tools build
          go-tools = self.packages.${system}.dotfiles-tools;
        }
      );
    };
}
