# SSH configuration
{ config, pkgs, lib, isDarwin, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "dev.galley.pub" = lib.hm.dag.entryBefore [ "*" ] {
        user = "galley";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
        extraOptions = {
          IdentityAgent = "none";
        };
      };
    } // lib.optionalAttrs isDarwin {
      "*" = {
        addKeysToAgent = "yes";
        extraOptions = {
          IdentityAgent = ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';
        };
      };
    };
  };
}
