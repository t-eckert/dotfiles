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
  };

  outputs = { self, nixpkgs, home-manager, darwin, flake-utils }:
    let
      # Supported systems
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

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

    in {
      # ============================================================
      # Packages - Go CLI tools
      # ============================================================
      packages = forAllSystems (system:
        let pkgs = pkgsFor system;
        in {
          # Individual tools
          dotfiles-tools = pkgs.callPackage ./nix/packages/go-tools.nix { };

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
            inherit self;
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
            inherit self;
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
      darwinConfigurations = {
        # Apple Silicon Mac
        "Thomas-MacBook-Pro" = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = {
            inherit self username;
          };
          modules = [
            ./nix/darwin
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  inherit self;
                  isDarwin = true;
                  isLinux = false;
                };
                users.${username} = import ./nix/home;
              };
            }
          ];
        };
      };

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
