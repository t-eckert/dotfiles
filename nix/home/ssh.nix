# SSH configuration
{ config, pkgs, lib, isDarwin, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # `settings` replaces the deprecated `matchBlocks`. Two things change:
    #   - keys are upstream OpenSSH directive names (HostName, not hostname), and
    #   - `extraOptions` is gone; those directives are now written inline.
    #
    # Values are rendered with `renderValue`: booleans become yes/no, everything
    # else goes through `toString` with NO quoting added. IdentityAgent below
    # therefore keeps its embedded quotes -- the path contains spaces, and
    # dropping them would silently break 1Password agent auth.
    settings = {
      "ardent-forge" = lib.hm.dag.entryBefore [ "*" ] {
        HostName = "ardent-forge.feist-gondola.ts.net";
        User = "thomaseckert";
      };

      "dev.galley.pub" = lib.hm.dag.entryBefore [ "*" ] {
        User = "galley";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
        IdentityAgent = "none";
      };
    } // lib.optionalAttrs isDarwin {
      "*" = {
        AddKeysToAgent = "yes";
        IdentityAgent = ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';
      };
    };
  };
}
