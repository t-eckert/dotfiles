{
  "model": "sonnet",
  "statusLine": {
    "type": "command",
    "command": "/Users/thomaseckert/.claude/statusline-command.sh"
  },
  "enabledPlugins": {
    "lua-lsp@claude-plugins-official": true,
    "rust-analyzer-lsp@claude-plugins-official": true,
    "gopls-lsp@claude-plugins-official": true,
    "typescript-lsp@claude-plugins-official": true,
    "code-simplifier@claude-plugins-official": true,
    "superpowers@claude-plugins-official": true,
    "ralph-loop@claude-plugins-official": true
  },
  "alwaysThinkingEnabled": true,
  "voice": {
    "enabled": true,
    "mode": "tap"
  },
  "skipDangerousModePermissionPrompt": true,
  "editorMode": "vim",
  "agentPushNotifEnabled": true,
  "voiceEnabled": true,
  "mcpServers": {
    "youtube": {
      "command": "npx",
      "args": [
        "-y",
        "zubeid-youtube-mcp-server"
      ],
      "env": {
        "YOUTUBE_API_KEY": "{{ op://Dotfiles/youtube-mcp/api-key }}"
      }
    }
  }
}
