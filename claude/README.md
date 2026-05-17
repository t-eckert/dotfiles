# Claude Code Configuration

Claude Code config is split between this repo (non-secrets) and 1Password (secrets).

## What's managed here

| File | Symlinked to | Notes |
|------|-------------|-------|
| `mcp.json` | `~/.claude/mcp.json` | Tolaria + chrome-devtools MCP servers |
| `statusline-command.sh` | `~/.claude/statusline-command.sh` | Status line script |
| `settings.json.tpl` | — | Template; generates `~/.claude/settings.json` via `op inject` |
| `../config/claude/statusline.sh` | `~/.config/claude/statusline.sh` | XDG status line script |
| `../config/claude/settings.json.tpl` | — | Template; generates `~/.config/claude/settings.json` via `op inject` |

The symlinks are managed by Home Manager (`nix/home/default.nix`). The generated settings files are not tracked — they contain API keys pulled from 1Password.

## 1Password setup

Create a **Dotfiles** vault in 1Password with these items:

| Item name | Field name | Contents |
|-----------|-----------|----------|
| `youtube-mcp` | `api-key` | YouTube Data API key |
| `linear-mcp` | `api-key` | Linear API key |

## Generating settings files

On a new machine, after running `./install.sh` (which calls `op inject` automatically), or manually:

```bash
op signin

op inject -i ~/Repos/github.com/t-eckert/dotfiles/claude/settings.json.tpl \
          -o ~/.claude/settings.json

op inject -i ~/Repos/github.com/t-eckert/dotfiles/config/claude/settings.json.tpl \
          -o ~/.config/claude/settings.json
```

## Adding a new secret MCP server

1. Add the server to `settings.json.tpl` using an `op://` reference:
   ```json
   "my-server": {
     "command": "npx",
     "args": ["my-mcp-package"],
     "env": {
       "API_KEY": "{{ op://Dotfiles/my-server-mcp/api-key }}"
     }
   }
   ```
2. Add a matching item to the **Dotfiles** vault in 1Password.
3. Re-run `op inject` to regenerate `~/.claude/settings.json`.

Never commit actual API keys to this repo.
