# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Setup and Installation

- **Initial setup**: Run `sudo ./install.sh` to install Homebrew packages, symlink configs, and install Go tools
- **Install tools only**: `go install ./tools/*`
- **Test a specific tool**: `go test ./tools/[tool-name]/`

## Repository Structure

This is a personal dotfiles repository that manages development environment configuration across multiple MacOS systems. It consists of two main components:

### Configuration Files (`./config/`)
Application configurations that get symlinked to `~/.config/` using stow:
- **nvim/**: Neovim configuration with custom Lua modules for statusline, tabline, winbar
- **ghostty/**: Terminal emulator configuration
- **zellij/**: Terminal multiplexer configuration  
- **atuin/**: Shell history sync configuration
- **gh/**: GitHub CLI configuration
- **k9s/**: Kubernetes cluster management tool configuration
- **helm/**: Kubernetes package manager configuration

### Custom Tools (`./tools/`)
Go CLI utilities for development workflows:
- **create-react-component**: Generates React components
- **fetch-gitignore**: Downloads gitignore templates from GitHub
- **normalize-lines**: Text formatting utility (80-char line breaks)
- **prepend**: Text prepending utility
- **serve**: Static file server
- **slug**: String slugification
- **teamtime**: Timezone utility for distributed teams

## Go Module Structure

The repository uses a single Go module (`github.com/t-eckert/dotfiles`) with tools as separate packages. Dependencies include:
- `github.com/jedib0t/go-pretty/v6` for table formatting
- `github.com/stretchr/testify` for testing

## Development Patterns

- Tools follow a simple CLI pattern with `main.go` files
- Testing uses testify for assertions
- Configuration files use standard formats (TOML, YAML, KDL)
- Neovim configuration is modularized with separate Lua files for UI components