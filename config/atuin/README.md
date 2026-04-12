# Atuin Shell History Configuration

This directory contains the Atuin configuration for syncing shell history across machines using Atuin's hosted sync service at `api.atuin.sh`.

## Server Details

- **Server**: `https://api.atuin.sh` (Atuin's hosted service)
- **Username**: thomas

## Initial Setup on New Machine

After running the dotfiles install script, follow these steps:

### 1. Install via Nix

Atuin is included in the Nix configuration. Run the dotfiles install script:

```bash
cd ~/Repos/github.com/t-eckert/dotfiles
./install.sh
```

Then apply the configuration:

```bash
darwin-rebuild switch --flake .
```

### 2. Login

Retrieve your credentials from 1Password (Atuin uses a username + password + encryption key):

```bash
atuin login -u thomas
# Enter password and encryption key when prompted
```

### 3. Enable Shell Integration

Already included in the dotfiles `.zshrc` via Nix home-manager (`programs.atuin.enableZshIntegration = true`).

### 4. Sync History

```bash
# Force initial sync to download history from server
atuin sync --force
```

## Configuration Details

### Sync Settings

- **Server**: `https://api.atuin.sh` (hosted)
- **Sync Frequency**: 5 minutes
- **Sync Version**: v2 (records-based sync enabled)
- **Auto-sync**: Enabled

### UI Preferences

- **Style**: Compact
- **Enter Behavior**: Immediately execute command
- **Search Mode**: Fuzzy (default)
- **Filter Mode**: Global (default)

### Security

- **Secrets Filter**: Enabled (filters AWS keys, GitHub PATs, etc.)
- **Encryption**: End-to-end encrypted with your personal key

## Troubleshooting

### Sync Errors

Check sync status:

```bash
atuin status
```

Force sync:

```bash
atuin sync --force
```

### Lost Encryption Key

Without the encryption key, you cannot decrypt your history. Keep it safe in 1Password.

## Updating Configuration

To update the Atuin configuration across all machines:

1. Edit `~/Repos/github.com/t-eckert/dotfiles/config/atuin/config.toml`
2. Commit and push changes
3. Pull dotfiles updates on other machines
4. Restart shell

## Statistics

```bash
atuin stats        # View statistics
atuin search <q>   # Or press Ctrl+R / up arrow in shell
```

## References

- [Atuin Documentation](https://docs.atuin.sh)
