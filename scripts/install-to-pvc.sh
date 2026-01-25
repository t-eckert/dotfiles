#!/bin/sh
# Install tools and configs to a PVC mount point
# Usage: install-to-pvc.sh [target-path]
# Default target: /mnt/tools

set -e

TARGET="${1:-/mnt/tools}"
SOURCE="/tools"

echo "Installing dotfiles tools to $TARGET..."
echo "Source: $SOURCE"

# Verify source exists
if [ ! -d "$SOURCE" ]; then
    echo "Error: Source directory $SOURCE not found"
    exit 1
fi

# Create target directories
mkdir -p "$TARGET/bin"
mkdir -p "$TARGET/share"
mkdir -p "$TARGET/config"

# Copy binaries
echo "Copying binaries..."
if [ -d "$SOURCE/bin" ]; then
    cp -r "$SOURCE/bin/"* "$TARGET/bin/" 2>/dev/null || true
    echo "  Installed $(ls "$TARGET/bin" 2>/dev/null | wc -l) binaries"
fi

# Copy share (man pages, completions, etc.)
echo "Copying share files..."
if [ -d "$SOURCE/share" ]; then
    cp -r "$SOURCE/share/"* "$TARGET/share/" 2>/dev/null || true
fi

# Copy configs
echo "Copying configs..."
if [ -d "$SOURCE/config" ]; then
    cp -r "$SOURCE/config/"* "$TARGET/config/" 2>/dev/null || true
fi

# Copy activation script
echo "Setting up activation script..."
if [ -f "$SOURCE/etc/activate.sh" ]; then
    cp "$SOURCE/etc/activate.sh" "$TARGET/activate.sh"
    chmod +x "$TARGET/activate.sh"
fi

# Write manifest
echo "Writing manifest..."
cat > "$TARGET/manifest.txt" << EOF
# Dotfiles Tools PVC
# https://github.com/t-eckert/dotfiles

Installed: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
Tools: $(ls "$TARGET/bin" 2>/dev/null | wc -l)

# To activate in your shell:
# source /home/user/.local/activate.sh
EOF

echo ""
echo "Installation complete!"
echo "  Binaries: $TARGET/bin/"
echo "  Configs:  $TARGET/config/"
echo "  Activate: source $TARGET/activate.sh"
echo ""
echo "$(ls "$TARGET/bin" 2>/dev/null | wc -l) tools installed."
