# Atuin Shell History Configuration

This directory contains the Atuin configuration for syncing shell history across machines using a self-hosted Atuin server.

## Server Details

- **Server**: `http://atuin-homelab.feist-gondola.ts.net:8888`
- **Version**: 18.11.0
- **Access**: Requires Tailscale connection to homelab network
- **Username**: thomas

## Initial Setup on New Machine

After running the dotfiles install script, follow these steps:

### 1. Install Atuin

```bash
# macOS
brew install atuin

# Linux
bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
```

### 2. Run Dotfiles Install

The `install.sh` script will automatically symlink the Atuin config:

```bash
cd ~/Repos/github.com/t-eckert/dotfiles
./install.sh
```

This creates: `~/.config/atuin/config.toml` → `~/Repos/github.com/t-eckert/dotfiles/config/atuin/config.toml`

### 3. Login to Homelab Server

Retrieve your encryption key from 1Password:

```bash
# Get encryption key from 1Password
op read "op://Homelab/Atuin Homelab Server/encryption key"
```

Then login to the server:

```bash
# Login with encryption key
atuin login -u thomas -k "YOUR_ENCRYPTION_KEY_HERE"

# Or login interactively
atuin login -u thomas
# Paste encryption key when prompted
```

### 4. Enable Shell Integration

Add to your shell configuration (already included in dotfiles `.zshrc`):

```bash
# For zsh
eval "$(atuin init zsh)"

# For bash
eval "$(atuin init bash)"
```

### 5. Sync History

```bash
# Force initial sync to download history from server
atuin sync --force
```

## Configuration Details

### Sync Settings

- **Server**: Homelab self-hosted instance (not public api.atuin.sh)
- **Sync Frequency**: 5 minutes (configurable in config.toml)
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
- **Network**: Requires Tailscale VPN access to homelab

## Troubleshooting

### Can't Connect to Server

Ensure you're connected to the Tailscale network:

```bash
tailscale status
```

Test server connectivity:

```bash
curl http://atuin-homelab.feist-gondola.ts.net:8888/
```

### Sync Errors

Check sync status:

```bash
atuin status
```

Force sync:

```bash
atuin sync --force
```

View detailed sync logs:

```bash
# Check Atuin logs (location varies by OS)
tail -f ~/.local/share/atuin/atuin.log
```

### Lost Encryption Key

Retrieve from 1Password:

```bash
op read "op://Homelab/Atuin Homelab Server/encryption key"
```

**Important**: Without the encryption key, you cannot decrypt your history. Keep it safe in 1Password.

## Updating Configuration

To update the Atuin configuration across all machines:

1. Edit `~/Repos/github.com/t-eckert/dotfiles/config/atuin/config.toml`
2. Commit and push changes
3. Pull dotfiles updates on other machines
4. Restart shell or run `atuin init` again

## Statistics

View your command history statistics:

```bash
atuin stats
```

Search your history interactively:

```bash
# Press Ctrl+R or up arrow in shell
# Or run directly:
atuin search <query>
```

## References

- [Atuin Documentation](https://docs.atuin.sh)
- [Homelab Atuin Deployment](https://github.com/t-eckert/homelab/tree/main/cluster/atuin)
- [1Password Item](op://Homelab/Atuin%20Homelab%20Server)
