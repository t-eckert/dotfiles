# SSH configuration
{ config, pkgs, lib, isDarwin, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # `settings` replaces the deprecated `matchBlocks`. It is freeform and takes
    # upstream OpenSSH directive names, so the camelCase aliases and the
    # separate `extraOptions` escape hatch both collapse into one flat block.
    # DAG ordering is unchanged. Booleans still render through yesNo, so
    # `true` becomes `yes` rather than `true`.
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
