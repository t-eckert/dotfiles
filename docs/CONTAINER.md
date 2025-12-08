# Container Usage Guide

This guide explains how to use the containerized development environment built from the dotfiles repository.

## Overview

The Containerfile creates a Debian-based development environment with:
- Full development stack (Go, Node.js, Python)
- All CLI tools from the Brewfile (where applicable to Debian)
- Neovim with your custom configuration
- Zsh with Oh My Zsh and custom configuration
- Persistent volumes for data that should survive container restarts

## Quick Start

### Build the Container

```bash
docker compose build
```

Or build directly with docker:

```bash
docker build -t dotfiles-dev -f Containerfile .
```

### Run Interactive Shell

```bash
# Using docker-compose (recommended)
docker compose run --rm devenv

# Using docker directly
docker run -it --rm \
  -v $(pwd):/workspace \
  -v nvim-data:/home/dev/.local/share/nvim \
  dotfiles-dev:latest
```

## Usage Patterns

### Interactive Development

Start an interactive shell for day-to-day development work:

```bash
docker compose run --rm devenv
```

This mounts your current directory as `/workspace` and starts a Zsh shell with all your configurations.

### Running Specific Commands

Execute a single command in the container:

```bash
# Run tests
docker compose run --rm devenv go test ./tools/...

# Build a project
docker compose run --rm devenv make build

# Run a script
docker compose run --rm devenv ./scripts/deploy.sh
```

### CI/Build Environment

Use in GitHub Actions or other CI systems:

```yaml
# .github/workflows/test.yml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests in container
        run: |
          docker build -t dotfiles-dev -f Containerfile .
          docker run --rm -v $PWD:/workspace dotfiles-dev go test ./...
```

## Persistent Volumes

The following data is persisted across container restarts:

| Volume | Path | Purpose |
|--------|------|---------|
| `nvim-data` | `/home/dev/.local/share/nvim` | Neovim plugins, LSP servers, treesitter parsers |
| `atuin-data` | `/home/dev/.local/share/atuin` | Atuin shell history database |
| `zsh-history` | `/home/dev/.config/zsh_history` | Zsh command history |
| `cache` | `/home/dev/.cache` | General application cache |
| `go-pkg` | `/home/dev/go/pkg` | Downloaded Go modules (speeds up builds) |

### Managing Volumes

```bash
# List volumes
docker volume ls | grep dotfiles

# Inspect a volume
docker volume inspect dotfiles-dev_nvim-data

# Remove all volumes (WARNING: deletes all persistent data)
docker compose down -v

# Backup a volume
docker run --rm -v dotfiles-dev_nvim-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/nvim-backup.tar.gz /data

# Restore a volume
docker run --rm -v dotfiles-dev_nvim-data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/nvim-backup.tar.gz -C /
```

## Mounting Options

### SSH Keys

To use SSH from within the container (for git operations):

Uncomment in `docker-compose.yml`:
```yaml
volumes:
  - ${HOME}/.ssh:/home/dev/.ssh:ro
```

Or with docker directly:
```bash
docker run -it --rm \
  -v $HOME/.ssh:/home/dev/.ssh:ro \
  -v $(pwd):/workspace \
  dotfiles-dev:latest
```

### Git Credentials

For user-specific git config:

Uncomment in `docker-compose.yml`:
```yaml
volumes:
  - ${HOME}/.gitconfig.local:/home/dev/.gitconfig.local:ro
```

### Docker-in-Docker

To use Docker from within the container:

Uncomment in `docker-compose.yml`:
```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

**Security Note:** Mounting the Docker socket gives the container full control over the Docker daemon. Only do this if you trust the container contents.

### Custom Workspace

Mount a different directory as workspace:

```bash
WORKSPACE_PATH=/path/to/project docker compose run --rm devenv
```

## Configuration

### User ID/GID Mapping

To avoid permission issues with mounted volumes, set the user UID/GID to match your host user:

```bash
docker compose build --build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g)
```

Default is 1000, which matches most development environments.

### Go Version

To use a different Go version:

```bash
docker compose build --build-arg GO_VERSION=1.23.0
```

## Troubleshooting

### Permission Issues

If you encounter permission errors with mounted files:

1. Check UID/GID matches:
   ```bash
   docker compose run --rm devenv id
   ```

2. Rebuild with matching UID/GID:
   ```bash
   docker compose build --build-arg USER_UID=$(id -u) --build-arg USER_GID=$(id -g)
   ```

### Volume Data Corruption

If persistent volumes become corrupted:

```bash
# Remove all volumes and rebuild
docker compose down -v
docker compose up --build
```

### Container Won't Start

Check the logs:

```bash
docker compose logs devenv
```

Rebuild from scratch:

```bash
docker compose down
docker compose build --no-cache
docker compose up
```

### Neovim Plugins Not Loading

Neovim plugins are installed on first run. If they're missing:

```bash
# Enter container
docker compose run --rm devenv

# Inside container, open Neovim and run
nvim +PackerSync
```

## Advanced Usage

### Running Long-Lived Container

Instead of `run`, use `up` to keep the container running:

```bash
# Start in background
docker compose up -d

# Attach to running container
docker compose exec devenv zsh

# Stop when done
docker compose down
```

### Multiple Containers

Run multiple instances with different workspaces:

```bash
# Terminal 1
WORKSPACE_PATH=~/project1 docker compose run --rm devenv

# Terminal 2
WORKSPACE_PATH=~/project2 docker compose run --rm devenv
```

### Customizing the Container

To add additional tools:

1. Edit `packages/debian.manifest` to add packages
2. Rebuild: `docker compose build`

Or install temporarily inside container:
```bash
docker compose run --rm devenv
# Inside container
sudo apt-get update && sudo apt-get install -y package-name
```

## Performance Tips

1. **Use named volumes for persistence** - They're faster than bind mounts on Mac/Windows
2. **Cache Go modules** - The `go-pkg` volume speeds up builds significantly
3. **Rebuild only when needed** - The multi-stage build caches layers efficiently
4. **Mount only what you need** - Fewer mounts = better performance

## Integration Examples

### VS Code Dev Containers

Create `.devcontainer/devcontainer.json`:

```json
{
  "name": "Dotfiles Dev Environment",
  "dockerComposeFile": "../docker-compose.yml",
  "service": "devenv",
  "workspaceFolder": "/workspace",
  "customizations": {
    "vscode": {
      "extensions": ["golang.go", "ms-python.python"]
    }
  }
}
```

### Makefile Integration

```makefile
.PHONY: shell test build

shell:
	docker compose run --rm devenv

test:
	docker compose run --rm devenv go test ./...

build:
	docker compose run --rm devenv go build -o bin/ ./...
```

## References

- [Containerfile](../Containerfile) - Multi-stage build definition
- [docker-compose.yml](../docker-compose.yml) - Orchestration configuration
- [DEBIAN.md](./DEBIAN.md) - Native Debian installation guide
