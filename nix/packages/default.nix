# Package exports
{ pkgs, ... }:

{
  dotfiles-tools = pkgs.callPackage ./go-tools.nix { };
}
