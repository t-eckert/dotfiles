#!/bin/bash
# Package manager abstraction layer for brew/apt

# Source logger if not already loaded
if ! command -v log_info &>/dev/null; then
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	source "$SCRIPT_DIR/logger.sh"
fi

# Update package cache
pm_update() {
	case "$PLATFORM" in
		macos)
			log_info "Updating Homebrew..."
			brew update
			;;
		debian)
			log_info "Updating apt cache..."
			sudo apt-get update
			;;
		*)
			log_error "Unsupported platform: $PLATFORM"
			return 1
			;;
	esac
}

# Install a single package
pm_install() {
	local package=$1

	case "$PLATFORM" in
		macos)
			log_info "Installing $package via Homebrew..."
			brew install "$package"
			;;
		debian)
			log_info "Installing $package via apt..."
			sudo apt-get install -y "$package"
			;;
		*)
			log_error "Unsupported platform: $PLATFORM"
			return 1
			;;
	esac
}

# Install from Brewfile (MacOS) or manifest file (Debian)
pm_install_list() {
	local file=$1

	case "$PLATFORM" in
		macos)
			if [ -f "$file" ]; then
				log_info "Installing packages from Brewfile..."
				brew bundle --file="$file"
			else
				log_warn "Brewfile not found: $file"
				return 1
			fi
			;;
		debian)
			if [ -f "$file" ]; then
				log_info "Installing packages from manifest: $file"
				# Read manifest and install packages by section
				local packages=()
				while IFS= read -r line; do
					# Skip empty lines and section headers
					if [[ -z "$line" || "$line" =~ ^\[.*\]$ || "$line" =~ ^# ]]; then
						continue
					fi
					# Remove inline comments and whitespace
					line=$(echo "$line" | sed 's/#.*//' | tr -d ' ')
					if [ -n "$line" ]; then
						packages+=("$line")
					fi
				done < "$file"

				if [ ${#packages[@]} -gt 0 ]; then
					sudo apt-get install -y "${packages[@]}"
				fi
			else
				log_warn "Manifest file not found: $file"
				return 1
			fi
			;;
		*)
			log_error "Unsupported platform: $PLATFORM"
			return 1
			;;
	esac
}

# Check if a package/command is installed
pm_is_installed() {
	local cmd=$1
	command -v "$cmd" &>/dev/null
}
