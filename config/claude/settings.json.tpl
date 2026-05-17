{
    "includeCoAuthoredBy": false,
    "statusLine": {
        "type": "command",
        "command": "~/.config/claude/statusline.sh",
        "padding": 0
    },
    "mcpServers": {
        "linear": {
            "command": "npx",
            "args": [
                "@modelcontextprotocol/server-linear"
            ],
            "env": {
                "LINEAR_API_KEY": "{{ op://Dotfiles/linear-mcp/api-key }}"
            }
        }
    }
}
