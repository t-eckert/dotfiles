# Neovim Obsidian Commands

This document lists all available Obsidian commands and keybindings configured in Neovim.

## Keybindings

All Obsidian keybindings use the `<Leader>o` prefix (where `<Leader>` is the space key).

### Quick Actions

| Key | Command | Description |
|-----|---------|-------------|
| `<Leader>x` | `:ObsidianToggleCheckbox` | Toggle checkbox state |

### Daily Notes

| Key | Command | Description |
|-----|---------|-------------|
| `<Leader>ot` | `:ObsidianToday` | Open today's daily note |
| `<Leader>om` | `:ObsidianTomorrow` | Open tomorrow's daily note |
| `<Leader>oy` | `:ObsidianYesterday` | Open yesterday's daily note |
| `<Leader>od` | `:ObsidianDailies` | Open picker list of all daily notes |

### Navigation and Search

| Key | Command | Description |
|-----|---------|-------------|
| `<Leader>oo` | `:ObsidianQuickSwitch` | Quick switch between notes by name |
| `<Leader>os` | `:ObsidianSearch` | Full-text search across all notes |
| `<Leader>ob` | `:ObsidianBacklinks` | Show notes that link to current note |
| `<Leader>oT` | `:ObsidianTags` | Search notes by tags |

### Note Management

| Key | Command | Description |
|-----|---------|-------------|
| `<Leader>on` | `:ObsidianNew` | Create a new note |
| `<Leader>or` | `:ObsidianRename` | Rename current note (updates all backlinks) |
| `<Leader>oh` | `:ObsidianTOC` | Show table of contents for current note |
| `<Leader>oO` | `:ObsidianOpen` | Open current note in Obsidian app |

### Templates and Media

| Key | Command | Description |
|-----|---------|-------------|
| `<Leader>opt` | `:ObsidianTemplate` | Insert a template into current note |
| `<Leader>opi` | `:ObsidianPasteImage` | Paste image from clipboard |

## Additional Commands

These commands can be run directly with `:CommandName` or `:Obsidian command_name`.

### Daily Notes with Offsets

```vim
:ObsidianToday -1        " Open yesterday's note
:ObsidianToday +1        " Open tomorrow's note
:ObsidianToday -7        " Open note from 7 days ago
```

### Note Creation

```vim
:ObsidianNew Title Here                    " Create new note with title
:ObsidianNewFromTemplate Title Template    " Create note from template
```

### Navigation

```vim
:ObsidianFollowLink          " Follow link under cursor
:ObsidianBacklinks           " Show backlinks to current note
```

### Workspace Management

```vim
:ObsidianWorkspace [NAME]    " Switch to another workspace
```

### Tags

```vim
:ObsidianTags tag1 tag2      " Find notes with specific tags
```

## Configuration

### Workspace Settings

- **Workspace Name:** Notebook
- **Workspace Path:** `~/Notebook`
- **Daily Notes Folder:** `Log/`
- **Templates Folder:** `+Templates/`

### UI Settings

- **Conceal Level:** 2 (hides markdown syntax for cleaner display)
- **Custom Checkboxes:**
  - `[ ]` - Todo (󰄱)
  - `[x]` - Done ()
  - `[>]` - Forward ()
  - `[~]` - Cancelled (󰰱)
  - `[!]` - Important ()

## Tips

1. **Quick Access to Today's Note:** `<Leader>ot` is your fastest way to open today's daily note
2. **Fast Note Switching:** Use `<Leader>oo` for fuzzy finding notes by name
3. **Find References:** Use `<Leader>ob` to see what notes link to your current note
4. **Offset Daily Notes:** You can use `:ObsidianToday -1` to quickly access recent daily notes
5. **Rename Safely:** When you rename a note with `<Leader>or`, all backlinks are automatically updated

## Plugin Information

- **Plugin:** [obsidian.nvim](https://github.com/obsidian-nvim/obsidian.nvim)
- **Custom Fork:** t-eckert/obsidian.nvim (branch: t-eckert/add-set-checkbox)
- **Configuration File:** `~/Repos/github.com/t-eckert/dotfiles/config/nvim/init.lua`
