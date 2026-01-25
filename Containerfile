# Multi-stage build for Kubernetes tools PVC
# Builds tools with Nix, then creates minimal runtime image

# Stage 1: Build with Nix
FROM nixos/nix:latest AS builder

# Enable flakes
RUN echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf

# Copy source
COPY . /src
WORKDIR /src

# Build the k8s tools volume
# The --no-link flag returns the path, we use it directly in the next stage
RUN nix build .#packages.x86_64-linux.k8s-tools-volume --no-link

# The build output is in ./result
RUN test -d result && echo "Build successful" || exit 1

# Stage 2: Minimal runtime image
FROM alpine:latest

# Install minimal dependencies for the install script
RUN apk add --no-cache coreutils bash

# Copy built tools from builder (copy the entire directory tree, preserving symlinks)
COPY --from=builder /src/result /tools

# Copy install script
COPY scripts/install-to-pvc.sh /install.sh
RUN chmod +x /install.sh

ENTRYPOINT ["/install.sh"]
