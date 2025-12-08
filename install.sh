#!/bin/bash
# Dotfiles installation dispatcher
# Detects platform and delegates to platform-specific installer
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source platform detection and logging
source "$SCRIPT_DIR/lib/platform-detect.sh"
source "$SCRIPT_DIR/lib/logger.sh"

# Detect platform
detect_platform

log_info "Detected platform: $PLATFORM"

# Delegate to platform-specific installer
case "$PLATFORM" in
	macos)
		log_info "Running MacOS installer..."
		exec "$SCRIPT_DIR/install-macos.sh" "$@"
		;;
	debian)
		log_info "Running Debian installer..."
		exec "$SCRIPT_DIR/install-debian.sh" "$@"
		;;
	*)
		log_error "Unsupported platform: $PLATFORM"
		log_error "This installation script supports MacOS and Debian only."
		exit 1
		;;
esac
