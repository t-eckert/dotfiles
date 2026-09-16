# syncshot — keep the Notebook vault synced to GitHub, always
{ config, pkgs, lib, isDarwin, ... }:

let
  vault = "${config.home.homeDirectory}/Notebook";

  # Deliberately the working checkout rather than a packaged derivation. This is
  # a tool under active development, and pointing launchd at the repo means an
  # edit takes effect on the next `launchctl kickstart` instead of a rebuild —
  # the same reasoning as the out-of-store symlink for the nvim config. The
  # trade is that the agent depends on the checkout being present; if syncshot
  # ever stops changing, package it under nix/packages and point here instead.
  syncshot = "${config.home.homeDirectory}/Repos/github.com/t-eckert/syncshot/syncshot.py";

  logFile = "${config.home.homeDirectory}/Library/Logs/syncshot.log";
in
{
  launchd.agents.syncshot = lib.mkIf isDarwin {
    enable = true;

    config = {
      # syncshot is stdlib-only, so a bare interpreter is all it needs.
      ProgramArguments = [ "${pkgs.python3}/bin/python3" syncshot ];

      # It syncs whatever directory it is launched from.
      WorkingDirectory = vault;

      RunAtLoad = true;

      # Restart on a crash, but not after a clean exit. syncshot handles SIGTERM
      # by finishing the current sync and returning 0, so `launchctl stop` means
      # stop and stays stopped; a plain `KeepAlive = true` would fight that and
      # relaunch it immediately. Use `launchctl kickstart -k` to restart.
      KeepAlive = { SuccessfulExit = false; };

      # Sync is background work and should yield to anything the user is doing.
      ProcessType = "Background";

      # launchd gives a job almost no PATH. git is needed directly, and ssh is
      # needed because the vault's repo-local core.sshCommand invokes a bare
      # `ssh` with a dedicated key (~/.ssh/notebook_ed25519, IdentityAgent=none).
      # That key is on disk and unencrypted, so pushes work with no agent and no
      # 1Password — which is what makes this safe to start at login, before
      # anything has been unlocked.
      EnvironmentVariables = {
        PATH = "${pkgs.git}/bin:${pkgs.openssh}/bin:/usr/bin:/bin";
      };

      # Both streams to one file, in the place macOS expects user logs. syncshot
      # logs events rather than ticks, so an idle day is a line or two; follow it
      # with `tail -f ~/Library/Logs/syncshot.log`. launchd does not rotate this,
      # so if it ever grows, that is the knob to add.
      StandardOutPath = logFile;
      StandardErrorPath = logFile;
    };
  };
}
