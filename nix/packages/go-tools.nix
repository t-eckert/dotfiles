# Build all Go CLI tools from ./tools/
{ lib, buildGoModule, fetchFromGitHub ? null }:

buildGoModule {
  pname = "dotfiles-tools";
  version = "0.1.0";

  # Use the local source (filtered to relevant files)
  src = lib.cleanSourceWith {
    src = ../..;
    filter = path: type:
      let
        baseName = baseNameOf path;
        relPath = lib.removePrefix (toString ../..) path;
      in
        # Include Go files
        lib.hasSuffix ".go" baseName ||
        # Include go.mod and go.sum
        baseName == "go.mod" ||
        baseName == "go.sum" ||
        # Include the tools directory structure
        lib.hasInfix "/tools/" relPath ||
        # Include directories needed for traversal
        type == "directory";
  };

  # Vendor hash - update after changing go.mod dependencies
  # Run: nix build .#dotfiles-tools 2>&1 | grep "got:" to get the correct hash
  vendorHash = "sha256-SyjF/ITuhiX8zgiJrKXzpOXl98jviKbYhiIAczQFAcM=";

  # Build all tools as subpackages
  subPackages = [
    "tools/create-react-component"
    "tools/fetch-gitignore"
    "tools/normalize-lines"
    "tools/prepend"
    "tools/serve"
    "tools/slug"
    "tools/teamtime"
  ];

  # Don't run tests during build (they can be run separately)
  doCheck = false;

  meta = with lib; {
    description = "Personal CLI tools for development workflows";
    homepage = "https://github.com/t-eckert/dotfiles";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.all;
  };
}
