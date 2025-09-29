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

	cd "$CONFIG_DIR" || exit

	for dir in *; do
		if [ -d "$dir" ]; then
			if [ "$dir" = "hammerspoon" ]; then
				# Hammerspoon config goes to ~/.hammerspoon
				target_dir="$HOME/.hammerspoon"
				echo "Creating directory $target_dir"
				mkdir -p "$target_dir"
				echo "Symlinking Hammerspoon config using stow..."
				stow -vt "$target_dir" "$dir"
			else
				# Other configs go to ~/.config
				target_dir="$HOME/.config/$(basename "$dir")"
				echo "Creating directory $target_dir"
				mkdir -p "$target_dir"
				echo "Symlinking using stow..."
				stow -vt "$target_dir" "$dir"
			fi
		fi
	done

	cd - || exit
else
	echo "No ./config directory found."
fi

# Symlink .zshrc to the home directory
echo "Copying .zshrc to home directory..."
cp -f "$PWD/.zshrc" "$HOME/.zshrc"

# Install tools
echo "Installing Tools"
go install ./tools/*

echo "Done."
