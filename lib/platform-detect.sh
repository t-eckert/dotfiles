#!/bin/bash
# Platform detection utilities for dotfiles installation

detect_platform() {
	case "$(uname -s)" in
		Darwin)
			PLATFORM="macos"
			;;
		Linux)
			if [ -f /etc/debian_version ]; then
				PLATFORM="debian"
			else
				PLATFORM="unknown"
			fi
			;;
		*)
			PLATFORM="unknown"
			;;
	esac
	export PLATFORM
}
