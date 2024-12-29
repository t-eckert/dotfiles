#!/bin/bash

# Ensure the script is run with sudo privileges if needed
if [[ $EUID -ne 0 ]]; then
	echo "Please run as root or with sudo"
	exit 1
fi

# Install Homebrew if not installed
if ! command -v brew &>/dev/null; then
	echo "Homebrew not found. Installing..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
	echo "Homebrew is already installed."
fi

# Install all packages from the Brewfile in the current directory
if [ -f "./Brewfile" ]; then
	echo "Installing packages from Brewfile..."
	brew bundle --file="./Brewfile"
else
	echo "No Brewfile found in the current directory."
fi

# Create directories in ~/.config and symlink them using stow
CONFIG_DIR="./config"
if [ -d "$CONFIG_DIR" ]; then
	echo "Setting up config directories..."

	for dir in "$CONFIG_DIR"/*; do
		if [ -d "$dir" ]; then
			target_dir="$HOME/.config/$(basename "$dir")"
			echo "Creating directory $target_dir"
			mkdir -p "$target_dir"
			echo "Symlinking using stow..."
			stow -vt "$target_dir" "$dir"
		fi
	done
else
	echo "No ./config directory found."
fi

# Symlink .zshrc to the home directory
echo "Symlinking .zshrc to home directory..."
ln -sf "$PWD/.zshrc" "$HOME/.zshrc"

echo "Done."
