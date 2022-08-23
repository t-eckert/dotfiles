#!/bin/bash

DOTFILES="$(pwd)"
COLOR_GRAY="\033[1;38;5;243m"
COLOR_BLUE="\033[1;34m"
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_PURPLE="\033[1;35m"
COLOR_YELLOW="\033[1;33m"
COLOR_NONE="\033[0m"

title() {
    echo -e "\n${COLOR_PURPLE}$1${COLOR_NONE}"
    echo -e "${COLOR_GRAY}==============================${COLOR_NONE}\n"
}

error() {
    echo -e "${COLOR_RED}Error: ${COLOR_NONE}$1"
    exit 1
}

warning() {
    echo -e "${COLOR_YELLOW}Warning: ${COLOR_NONE}$1"
}

info() {
    echo -e "${COLOR_BLUE}Info: ${COLOR_NONE}$1"
}

success() {
    echo -e "${COLOR_GREEN}$1${COLOR_NONE}"
}


title "Setting up Homebrew"

if test ! "$(command -v brew)"; then
	info "Homebrew not installed. Installing."
	# Run as a login shell (non-interactive) so that the script doesn't pause for user input
	curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash --login
fi

# install brew dependencies from Brewfile
brew bundle

# install fzf
echo -e
info "Installing fzf"
"$(brew --prefix)"/opt/fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish


title "Adding /scripts to PATH"
export PATH=$PATH:$DOTFILES/scripts

