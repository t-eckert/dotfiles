# Thomas Eckert's Dotfiles

This repository helps me unify development environments between multiple MacOS systems. It contains configuration files for applications I use and small sharp tools I've written to make my work more effective.

## Installation

Clone the repository and run `./install.sh`:

```bash
./install.sh
```

This will:
1. Install Nix via Determinate Systems installer
2. Configure your user as a trusted user (no more sudo for nix commands!)
3. Set up nix-darwin for macOS system configuration
4. Apply Home Manager for user environment

After installation, apply the full configuration:

```bash
# First time: Bootstrap nix-darwin
nix run nix-darwin -- switch --flake .

# Subsequent updates:
darwin-rebuild switch --flake .
# Or use the alias: reload-nix
```

## Adding a new machine

`darwin-rebuild --flake .` resolves `darwinConfigurations.$(hostname -s)`. macOS
picks that hostname from the account's full name during setup, so it is not
consistent between machines — one Mac is `Thomas-MacBook-Pro`, another is
`Thomass-MacBook-Pro`.

To onboard a new Mac:

```bash
# 1. Activate without caring about the hostname
task bootstrap          # or: nix run nix-darwin -- switch --flake .#default

# 2. Add the machine's name to `darwinHosts` in flake.nix
task hosts              # shows this machine's name and the configured ones

# 3. From then on, the bare form works
task rebuild            # or: darwin-rebuild switch --flake .
```

Each listed hostname pins itself via `networking.hostName` in
[`nix/darwin`](./nix/darwin), so once a machine has switched, its name and the
flake cannot drift apart.

### Troubleshooting

**`error: flake ... does not provide attribute 'darwinConfigurations.<name>.system'`**

The machine's hostname is not in `darwinHosts`. Either activate explicitly with
an existing config:

```bash
nix run nix-darwin -- switch --flake .#default
```

or add the hostname to `darwinHosts` in `flake.nix` and switch normally.

**If nix commands require sudo:**

The installer automatically configures trusted users, but if you need to do it manually:

```bash
# Add yourself to trusted users
sudo tee -a /etc/nix/nix.custom.conf > /dev/null <<EOF

# Allow user to run nix commands without sudo
trusted-users = root $(whoami)
EOF

# Restart the nix daemon
sudo launchctl kickstart -k system/systems.determinate.nix-daemon

# Verify you're trusted
nix store ping  # Should show "Trusted: 1"
```

## Configs

- [Atuin](./config/atuin)
- [GitHub CLI](./config/gh)
- [Ghostty](./config/ghostty)
- [Helm](./config/helm)
- [K9s](./config/k9s)
- [Neovim](./config/nvim)
- [Zellij](./config/zellij)

## Tools

I've unified my tooling around simple Go applications. They are all available in [`tools`](./tools). The install script 

- [`create-react-component`](./tools/create-react-component) generates a new React component with the given name.
- [`fetch-gitignore`](./tools/fetch-gitignore) fetches a `.gitignore` file from the GitHub gitignore repository.
- [`normalize-lines`](./tools/normalize-lines) normalizes lines in a string of text to be 80 characters long without breaking words.
- [`prepend`](./tools/prepend) a file renaming tool which will prepend a given string to a glob.
- [`serve`](./tools/serve) serve the current directory as a file server.
- [`slug`](./tools/slug) 
- [`teamtime`](./tools/teamtime) tells you what time is is for everyone on your team.
