# Claude Code Configuration

This directory contains reusable Claude Code configurations for use across projects.

## Structure

- `settings.local.json` - Project-specific settings (permissions, MCP servers, etc.)
- `commands/` - Custom slash commands that can be used with `/command-name`

## Slash Commands

Commands are markdown files in the `commands/` directory. When you type `/command-name`, Claude Code expands it to the prompt defined in the file.

### Available Commands

- `/review` - Comprehensive code review focusing on quality, security, and best practices
- `/optimize` - Analyze and suggest performance optimizations
- `/explain` - Detailed explanation of code functionality and design decisions
- `/test` - Generate comprehensive test coverage for code
- `/refactor` - Suggest refactoring improvements without changing functionality

### Creating New Commands

1. Create a new `.md` file in `commands/` directory
2. The filename becomes the command name (e.g., `example.md` → `/example`)
3. Write the prompt content in the file
4. Use the command in Claude Code by typing `/command-name`

## Using in Other Projects

### Automated Setup (Recommended)

Run the setup script from this repository:

```bash
# From the dotfiles repository
./.claude/setup-project.sh /path/to/project

# Or from another directory
~/path/to/dotfiles/.claude/setup-project.sh .
```

The script will ask whether you want to:
1. **Symlink** - Commands stay in sync with your dotfiles (recommended for your own projects)
2. **Copy** - Independent commands that won't change (useful for shared/team projects)

### Manual Setup

#### Copy to Project
```bash
cp -r ~/path/to/dotfiles/.claude/commands /path/to/project/.claude/
```

#### Symlink Commands (Shared Across Projects)
```bash
ln -s ~/path/to/dotfiles/.claude/commands /path/to/project/.claude/commands
```

## Settings

The `settings.local.json` file is specific to this repository. For project-specific settings:
- Copy the template and modify for each project's needs
- Configure MCP servers, permissions, and hooks per-project
- See Claude Code documentation for full settings reference

## Skills

Skills are more complex than commands and can be installed via the Claude Code CLI or skill packages. Currently no custom skills are configured in this repository.

To add skills in the future, follow Claude Code's skill installation documentation.
