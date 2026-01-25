# Multi-stage build for Kubernetes tools PVC
# Builds tools with Nix, then creates minimal runtime image

# Stage 1: Build with Nix
FROM nixos/nix:latest AS builder

# Enable flakes
RUN echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf

# Copy source
COPY . /src
WORKDIR /src

# Build the k8s tools volume and keep the symlink for easy access
RUN nix build .#packages.x86_64-linux.k8s-tools-volume

# Verify the build succeeded
RUN test -L result && echo "Build successful: $(readlink result)" || exit 1

# Stage 2: Minimal runtime image
FROM alpine:latest

# Install minimal dependencies for the install script
RUN apk add --no-cache coreutils bash

# Copy built tools from builder
# The 'result' symlink points into the nix store
COPY --from=builder /src/result /tools

# Copy install script
COPY scripts/install-to-pvc.sh /install.sh
RUN chmod +x /install.sh

ENTRYPOINT ["/install.sh"]
