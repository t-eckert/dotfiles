# SSH configuration
{ config, pkgs, lib, isDarwin, ... }:

{
  programs.ssh = {
    enable = true;

    # Extra SSH configuration
    extraConfig = lib.optionalString isDarwin ''
      Host *
        IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
        AddKeysToAgent yes
    '';
  };
}
