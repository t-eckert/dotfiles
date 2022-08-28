#!/bin/bash

DOTFILES="$(pwd)"

echo "Setting up Homebrew"

if test ! "$(command -v brew)"; then
	info "Homebrew not installed. Installing."
	# Run as a login shell (non-interactive) so that the script doesn't pause for user input
	curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash --login
fi

# install brew dependencies from Brewfile
brew bundle

echo "Adding /scripts to PATH"
export PATH=$PATH:$DOTFILES/scripts

echo "Installing utilities"
cd ./utilities/normalize-lines/
go install .
cd ./utilities/teamtime/
go install .
