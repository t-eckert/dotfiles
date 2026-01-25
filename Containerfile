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
RUN nix build .#packages.x86_64-linux.k8s-tools-volume --no-link --print-out-paths > /tmp/result-path

# Copy result to a fixed location (nix store paths are hashed)
RUN cp -rL $(cat /tmp/result-path) /build-output

# Stage 2: Minimal runtime image
FROM alpine:latest

# Install minimal dependencies for the install script
RUN apk add --no-cache coreutils

# Copy built tools from builder
COPY --from=builder /build-output /tools

# Copy install script
COPY scripts/install-to-pvc.sh /install.sh
RUN chmod +x /install.sh

ENTRYPOINT ["/install.sh"]
