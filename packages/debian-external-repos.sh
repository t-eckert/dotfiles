#!/bin/bash
# Setup external package repositories for Debian
set -euo pipefail

# Source logger if available
if [ -f "./lib/logger.sh" ]; then
	source ./lib/logger.sh
else
	log_info() { echo "[INFO] $1"; }
	log_warn() { echo "[WARN] $1"; }
	log_error() { echo "[ERROR] $1"; }
fi

# GitHub CLI
setup_github_cli() {
	log_info "Adding GitHub CLI repository..."
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
		sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
		sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
}

# Docker
setup_docker() {
	log_info "Adding Docker repository..."
	sudo install -m 0755 -d /etc/apt/keyrings
	curl -fsSL https://download.docker.com/linux/debian/gpg | \
		sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null
	sudo chmod a+r /etc/apt/keyrings/docker.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
		sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
}

# Kubernetes CLI
setup_kubernetes() {
	log_info "Adding Kubernetes repository..."
	sudo mkdir -p /etc/apt/keyrings
	curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | \
		sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg 2>/dev/null
	echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | \
		sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
}

# HashiCorp (Terraform, etc.)
setup_hashicorp() {
	log_info "Adding HashiCorp repository..."
	wget -O- https://apt.releases.hashicorp.com/gpg 2>/dev/null | \
		sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg 2>/dev/null
	echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
		sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
}

# Node.js (via NodeSource)
setup_nodejs() {
	log_info "Adding Node.js repository..."
	curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - > /dev/null
}

# Helm
setup_helm() {
	log_info "Adding Helm repository..."
	curl https://baltocdn.com/helm/signing.asc 2>/dev/null | \
		sudo gpg --dearmor -o /usr/share/keyrings/helm.gpg 2>/dev/null
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | \
		sudo tee /etc/apt/sources.list.d/helm-stable-debian.list > /dev/null
}

# Tailscale
setup_tailscale() {
	log_info "Adding Tailscale repository..."
	curl -fsSL https://pkgs.tailscale.com/stable/debian/$(lsb_release -cs).noarmor.gpg | \
		sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
	curl -fsSL https://pkgs.tailscale.com/stable/debian/$(lsb_release -cs).tailscale-keyring.list | \
		sudo tee /etc/apt/sources.list.d/tailscale.list > /dev/null
}

# Azure CLI
setup_azure_cli() {
	log_info "Adding Azure CLI repository..."
	curl -sL https://packages.microsoft.com/keys/microsoft.asc | \
		gpg --dearmor | \
		sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null
	sudo chmod go+r /etc/apt/keyrings/microsoft.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | \
		sudo tee /etc/apt/sources.list.d/azure-cli.list > /dev/null
}

# Main execution
setup_external_repos() {
	log_info "Setting up external repositories for Debian..."

	# Setup each repo (comment out any you don't need)
	setup_github_cli
	setup_docker
	setup_kubernetes
	setup_hashicorp
	setup_nodejs
	setup_helm
	setup_tailscale
	setup_azure_cli

	# Refresh package cache after adding repos
	log_info "Updating package cache..."
	sudo apt-get update

	log_info "External repositories setup complete!"
	log_info "You can now install packages like: gh, docker-ce, kubectl, terraform, helm, nodejs, tailscale, az"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" -ef "$0" ]; then
	setup_external_repos
fi
