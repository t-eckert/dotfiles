# Thomas Eckert's Dotfiles

This repository helps me unify development environments between multiple MacOS systems. It contains configuration files for applications I use and small sharp tools I've written to make my work more effective.

## Installation

Clone the repository and run `sudo ./install.sh`.

## Configs

- [Atuin](./.config/atuin)
- [GitHub CLI](./.config/gh)
- [Ghostty](./.config/ghostty)
- [Helm](./.config/helm)
- [K9s](./.config/k9s)
- [Neovim](./.config/nvim)
- [Zellij](./.config/zellij)

## Tools

I've unified my tooling around simple Go applications. They are all available in [`tools`](./tools). The install script 

- [`create-react-component`](./tools/create-react-component) generates a new React component with the given name.
- [`fetch-gitignore`](./tools/fetch-gitignore) fetches a `.gitignore` file from the GitHub gitignore repository.
- [`normalize-lines`](./tools/normalize-lines) normalizes lines in a string of text to be 80 characters long without breaking words.
- [`prepend`](./tools/prepend) a file renaming tool which will prepend a given string to a glob.
- [`serve`](./tools/serve) serve the current directory as a file server.
- [`slug`](./tools/slug) 
- [`teamtime`](./tools/teamtime) tells you what time is is for everyone on your team.
