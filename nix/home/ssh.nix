# SSH configuration
{ config, pkgs, lib, isDarwin, ... }:

{
  programs.ssh = {
    enable = true;

    matchBlocks = {
      "dev.galley.pub" = {
        user = "galley";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
        extraOptions = {
          IdentityAgent = "none";
        };
      };
    };

    # Extra SSH configuration
    extraConfig = lib.optionalString isDarwin ''
      Host *
        IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
        AddKeysToAgent yes
    '';
  };
}
