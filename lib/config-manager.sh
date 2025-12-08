#!/bin/bash
# Configuration management for dotfiles with platform awareness

# Source dependencies
if ! command -v log_info &>/dev/null; then
	SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	source "$SCRIPT_DIR/logger.sh"
fi

# Backup directory with timestamp
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# Backup function
backup_file() {
	local file=$1
	if [ -e "$file" ]; then
		mkdir -p "$BACKUP_DIR"
		log_info "Backing up $file to $BACKUP_DIR"
		cp -r "$file" "$BACKUP_DIR/"
	fi
}

# Check if an app should be skipped on current platform
should_skip_app() {
	local app=$1

	case "$PLATFORM:$app" in
		debian:hammerspoon)
			return 0  # Skip hammerspoon on Debian
			;;
		*)
			return 1  # Don't skip
			;;
	esac
}

# Check if config has platform-specific variants
has_variants() {
	local app=$1
	local dotfiles_root=${DOTFILES_ROOT:-.}
	[ -d "$dotfiles_root/config-variants/$app" ]
}

# Process template file with environment variable substitution
process_template() {
	local template=$1
	local output=$2

	# Set default XDG_CONFIG_HOME if not set
	export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

	log_info "Processing template: $template → $output"
	if command -v envsubst &>/dev/null; then
		envsubst < "$template" > "$output"
	else
		log_warn "envsubst not found, copying template as-is"
		cp "$template" "$output"
	fi
}

# Setup config variant for platform
setup_variant_config() {
	local app=$1
	local dotfiles_root=${DOTFILES_ROOT:-.}
	local config_dir="$dotfiles_root/config/$app"

	# Check for template files
	if [ -f "$dotfiles_root/config-variants/$app/config.template" ] || \
	   [ -f "$dotfiles_root/config-variants/$app/config.yaml.template" ]; then

		local template_file
		if [ -f "$dotfiles_root/config-variants/$app/config.template" ]; then
			template_file="$dotfiles_root/config-variants/$app/config.template"
			local output_file="$config_dir/config"
		else
			template_file="$dotfiles_root/config-variants/$app/config.yaml.template"
			local output_file="$config_dir/config.yaml"
		fi

		mkdir -p "$config_dir"
		process_template "$template_file" "$output_file"
		return
	fi

	# Check for platform-specific variants
	local variant_file="$dotfiles_root/config-variants/$app/config.$PLATFORM"
	if [ -f "$variant_file" ]; then
		log_info "Using platform-specific config for $app: $PLATFORM"
		mkdir -p "$config_dir"
		cp "$variant_file" "$config_dir/config"
	fi
}

# Setup standard config using stow
setup_standard_config() {
	local app=$1
	local dotfiles_root=${DOTFILES_ROOT:-.}
	local config_dir="$dotfiles_root/config"

	cd "$config_dir" || return 1

	# Special handling for hammerspoon (goes to ~/.hammerspoon on MacOS)
	if [ "$app" = "hammerspoon" ] && [ "$PLATFORM" = "macos" ]; then
		target_dir="$HOME/.hammerspoon"
		backup_file "$target_dir"
		log_info "Creating directory $target_dir"
		mkdir -p "$target_dir"
		log_info "Symlinking Hammerspoon config using stow..."
		stow -vt "$target_dir" "$app" 2>&1 | grep -v "BUG in find_stowed_path" || true
	else
		# Other configs go to ~/.config
		target_dir="$HOME/.config/$(basename "$app")"
		backup_file "$target_dir"
		log_info "Creating directory $target_dir"
		mkdir -p "$target_dir"
		log_info "Symlinking $app using stow..."
		stow -vt "$target_dir" "$app" 2>&1 | grep -v "BUG in find_stowed_path" || true
	fi

	cd - >/dev/null || return 1
}

# Setup all configs with platform awareness
setup_configs() {
	local dotfiles_root=${DOTFILES_ROOT:-.}
	local config_dir="$dotfiles_root/config"

	if [ ! -d "$config_dir" ]; then
		log_warn "No ./config directory found."
		return 1
	fi

	log_info "Setting up config directories..."

	for dir in "$config_dir"/*; do
		if [ -d "$dir" ]; then
			local app=$(basename "$dir")

			# Skip platform-specific apps
			if should_skip_app "$app"; then
				log_info "Skipping $app (not supported on $PLATFORM)"
				continue
			fi

			# Handle variant configs
			if has_variants "$app"; then
				setup_variant_config "$app"
			fi

			# Setup standard stow config
			setup_standard_config "$app"
		fi
	done
}

# Symlink dotfiles to home directory
symlink_dotfile() {
	local file=$1
	local dotfiles_root=${DOTFILES_ROOT:-.}

	if [ -f "$dotfiles_root/$file" ]; then
		backup_file "$HOME/$file"
		log_info "Symlinking $file to home directory..."
		ln -sf "$dotfiles_root/$file" "$HOME/$file"
	else
		log_warn "$file not found in dotfiles directory"
	fi
}

# Setup platform-specific zshrc.d files
setup_zshrc_platform() {
	local dotfiles_root=${DOTFILES_ROOT:-.}
	local zshrc_platform_dir="$HOME/.config/zshrc.d"

	mkdir -p "$zshrc_platform_dir"

	# Determine platform name for zshrc.d
	local platform_name
	case "$PLATFORM" in
		macos)
			platform_name="darwin"
			;;
		debian)
			platform_name="linux"
			;;
		*)
			log_warn "Unknown platform for zshrc.d: $PLATFORM"
			return 1
			;;
	esac

	local source_file="$dotfiles_root/config-variants/zshrc.d/platform-$platform_name.zsh"
	local target_file="$zshrc_platform_dir/platform-$platform_name.zsh"

	if [ -f "$source_file" ]; then
		log_info "Setting up platform-specific zsh config for $platform_name..."
		cp "$source_file" "$target_file"
	else
		log_warn "Platform-specific zsh config not found: $source_file"
	fi
}
