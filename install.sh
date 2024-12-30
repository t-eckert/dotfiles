#!/bin/bash

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

	cd "$CONFIG_DIR"

	for dir in *; do
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
echo "Copying .zshrc to home directory..."
cp -f "$PWD/.zshrc" "$HOME/.zshrc"

echo "Done."
