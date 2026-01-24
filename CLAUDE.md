# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Setup and Installation

- **Initial setup**: Run `sudo ./install.sh` to install Homebrew packages, symlink configs, and install Go tools
- **Install tools only**: `go install ./tools/*`
- **Run all tests**: `go test ./...`
- **Test a specific tool**: `go test ./tools/[tool-name]/`

## Repository Structure

This is a personal dotfiles repository that manages development environment configuration across multiple MacOS systems.

### Configuration Files (`./config/`)
Application configurations that get symlinked to `~/.config/` using stow:
- **nvim/**: Neovim configuration (lazy.nvim plugin manager, custom Lua modules)
- **ghostty/**: Terminal emulator configuration
- **zellij/**: Terminal multiplexer configuration
- **atuin/**: Shell history sync configuration
- **gh/**: GitHub CLI configuration
- **k9s/**: Kubernetes cluster management tool configuration
- **helm/**: Kubernetes package manager configuration
- **hammerspoon/**: Window management (symlinks to `~/.hammerspoon` instead of `~/.config`)

### Shell and Git Config (root level)
Symlinked directly to home directory:
- `.zshrc`: Zsh configuration with Oh My Zsh plugins
- `.gitconfig`: Git configuration
- `.editorconfig`: Editor configuration

### Custom Tools (`./tools/`)
Go CLI utilities for development workflows. Each tool has its own directory with `main.go` and optional `README.md`.

### Brewfile
Defines Homebrew packages installed during setup via `brew bundle`.

## Go Module Structure

Single Go module (`github.com/t-eckert/dotfiles`) with tools as separate packages. Dependencies:
- `github.com/jedib0t/go-pretty/v6` for table formatting
- `github.com/stretchr/testify` for testing

## Development Patterns

- Tools follow a simple CLI pattern with `main.go` files
- Testing uses testify for assertions
- Configuration files use standard formats (TOML, YAML, KDL, Lua)
- Neovim configuration uses lazy.nvim with plugins organized by category (LSP, Git, UI, etc.)
