# Claude Code — per-machine profiles
#
# The same flake configures the personal and the work Mac, and the work Mac runs
# its own Claude Code signed in through the employer. This module keeps the two
# from bleeding into each other:
#
#   null        nothing is managed (the default: Linux, the public container,
#               and Macs not yet listed in flake.nix)
#   "work"      only the shared, identity-free pieces (the status line)
#   "personal"  the shared pieces plus ~/.claude/CLAUDE.md
#
# This repo is public, so nothing personal is stored in it. The personal
# CLAUDE.md is an out-of-store symlink to a file kept outside the repo; only its
# path lives here. Credentials, ~/.claude.json and settings.local.json are never
# managed.
#
# ~/.claude/settings.json is deliberately not a Home Manager link: Claude Code
# writes to it (permission approvals, /config), and a read-only store link would
# break that. Activation merges the few keys we own into it instead.
{ config, pkgs, lib, ... }:

let
  cfg = config.claude;

  statusline = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = with pkgs; [ jq git coreutils ];
    text = builtins.readFile ../../config/claude/statusline.sh;
  };

  # Keys merged into ~/.claude/settings.json on every activation. Everything
  # else in that file is left as Claude Code wrote it.
  managedSettings = {
    statusLine = {
      type = "command";
      command = "${config.home.homeDirectory}/.claude/statusline.sh";
    };
  };
in
{
  options.claude = {
    profile = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "personal" "work" ]);
      default = null;
      description = "Which Claude Code profile this machine gets. null manages nothing.";
    };

    personal.claudeMd = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/Users/thomaseckert/.config/claude-personal/CLAUDE.md";
      description = ''
        Absolute path to the personal global CLAUDE.md, kept outside this public
        repo. Linked to ~/.claude/CLAUDE.md on the personal profile.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.profile != null) {
      # A stable path for settings.json to point at; the target changes per build.
      home.file.".claude/statusline.sh".source = "${statusline}/bin/claude-statusline";

      home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        settings="$HOME/.claude/settings.json"
        if [[ ! -v DRY_RUN ]]; then
          mkdir -p "$HOME/.claude"
          [[ -s "$settings" ]] || echo '{}' > "$settings"
          tmp="$(mktemp)"
          if ${pkgs.jq}/bin/jq --argjson managed ${lib.escapeShellArg (builtins.toJSON managedSettings)} \
              '. * $managed' "$settings" > "$tmp"; then
            # cat, not mv: keeps the file's inode, mode and any symlink intact
            cat "$tmp" > "$settings"
          else
            echo "claude: $settings is not valid JSON; left unchanged" >&2
          fi
          rm -f "$tmp"
        fi
      '';

      # Claude Code itself is not a Nix package: a store copy goes stale and
      # sits on PATH behind the self-updating one, so losing ~/.local/bin from
      # PATH would silently run an old version. Instead, bootstrap the native
      # install once on a fresh machine and let `claude update` own it after.
      home.activation.claudeInstall = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [[ ! -v DRY_RUN && ! -e "$HOME/.local/bin/claude" ]]; then
          # The installer shells out to curl itself, so it needs it on PATH.
          ( export PATH="${lib.makeBinPath (with pkgs; [ curl coreutils ])}:$PATH"
            curl -fsSL https://claude.ai/install.sh | ${pkgs.bash}/bin/bash ) \
            || echo "claude: native install failed; run 'curl -fsSL https://claude.ai/install.sh | bash' by hand" >&2
        fi
      '';
    })

    (lib.mkIf (cfg.profile == "personal") {
      assertions = [{
        assertion = cfg.personal.claudeMd != null;
        message = "claude.profile = \"personal\" needs claude.personal.claudeMd set to a path outside the repo.";
      }];

      home.file.".claude/CLAUDE.md" = lib.mkIf (cfg.personal.claudeMd != null) {
        source = config.lib.file.mkOutOfStoreSymlink cfg.personal.claudeMd;
      };
    })
  ];
}
