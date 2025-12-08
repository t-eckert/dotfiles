# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Setup and Installation

### Platform Support

This repository now supports both MacOS and Debian (native and containerized):

| Platform | Native Install | Container |
|----------|----------------|-----------|
| MacOS    | ✅ Homebrew    | N/A       |
| Debian   | ✅ apt         | ✅ Docker |

### Installation Methods

- **Auto-detect platform**: Run `./install.sh` (detects MacOS or Debian)
- **MacOS specific**: Run `./install-macos.sh`
- **Debian specific**: Run `./install-debian.sh`
- **Container**: Run `docker compose build && docker compose run --rm devenv`
- **Install tools only**: `go install ./tools/*`
- **Test a specific tool**: `go test ./tools/[tool-name]/`

## Repository Structure

This is a personal dotfiles repository that manages development environment configuration across multiple systems (MacOS and Debian). It consists of six main components:

### Configuration Files (`./config/`)
Application configurations that get symlinked to `~/.config/` using stow:
- **nvim/**: Neovim configuration with custom Lua modules for statusline, tabline, winbar
- **ghostty/**: Terminal emulator configuration
- **zellij/**: Terminal multiplexer configuration  
- **atuin/**: Shell history sync configuration
- **gh/**: GitHub CLI configuration
- **k9s/**: Kubernetes cluster management tool configuration
- **helm/**: Kubernetes package manager configuration

### Claude Code Configuration (`./.claude/`)
Reusable Claude Code commands and settings:
- **commands/**: Slash commands for common development tasks
  - `/review` - Code review focusing on quality, security, best practices
  - `/optimize` - Performance optimization analysis
  - `/explain` - Detailed code explanations
  - `/test` - Generate comprehensive test coverage
  - `/refactor` - Suggest refactoring improvements
  - `/debug` - Help debug issues with step-by-step analysis
  - `/document` - Generate or improve documentation
- **setup-project.sh**: Script to install commands in other projects (symlink or copy)
- **settings.local.json**: Project-specific Claude Code settings

### Custom Tools (`./tools/`)
Go CLI utilities for development workflows:
- **create-react-component**: Generates React components
- **fetch-gitignore**: Downloads gitignore templates from GitHub
- **normalize-lines**: Text formatting utility (80-char line breaks)
- **prepend**: Text prepending utility
- **serve**: Static file server
- **slug**: String slugification
- **teamtime**: Timezone utility for distributed teams

### Shared Libraries (`./lib/`)
Reusable bash functions for installation scripts:
- **logger.sh**: Logging functions (log_info, log_warn, log_error)
- **platform-detect.sh**: OS detection (Darwin→macos, Linux/Debian→debian)
- **package-manager.sh**: Package management abstraction (brew/apt)
- **config-manager.sh**: Configuration symlinking with platform awareness

### Package Mappings (`./packages/`)
Debian package management files:
- **package-map.json**: Brewfile → Debian package mappings
- **debian.manifest**: Ordered package installation list
- **debian-external-repos.sh**: External repository setup (GitHub CLI, Docker, HashiCorp, etc.)

### Config Variants (`./config-variants/`)
Platform-specific configuration variants:
- **k9s/config.yaml.template**: Uses XDG paths instead of MacOS-specific paths
- **ghostty/config.{macos,debian}**: Platform-specific terminal configs
- **zshrc.d/platform-{darwin,linux}.zsh**: Platform-specific PATH and environment settings

### Container Environment
Debian-based containerized development environment:
- **Containerfile**: Multi-stage build (base, repos, packages, toolchains, dotfiles)
- **docker-compose.yml**: Dev environment orchestration with persistent volumes
- **.dockerignore**: Build optimization
- See [docs/CONTAINER.md](docs/CONTAINER.md) for usage details

### Installation Scripts
Cross-platform installation with automatic detection:
- **install.sh**: Platform dispatcher (auto-detects MacOS or Debian)
- **install-macos.sh**: MacOS-specific installer (uses Homebrew, Brewfile)
- **install-debian.sh**: Debian-specific installer (uses apt, external repos)

## Go Module Structure

The repository uses a single Go module (`github.com/t-eckert/dotfiles`) with tools as separate packages. Dependencies include:
- `github.com/jedib0t/go-pretty/v6` for table formatting
- `github.com/stretchr/testify` for testing

## Development Patterns

- Tools follow a simple CLI pattern with `main.go` files
- Testing uses testify for assertions
- Configuration files use standard formats (TOML, YAML, KDL)
- Neovim configuration is modularized with separate Lua files for UI components