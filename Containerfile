# Devcontainer: self-contained personal development environment
# Builds the full thomaseckert@linux home-manager configuration into a
# portable image you can shell into on any system that runs containers.
#
# Build:  podman build -t devenv .
# Run:    podman run -it --rm devenv
# Persist workdir: podman run -it --rm -v $(pwd):/workspace devenv

FROM docker.io/nixos/nix:latest

# Enable flakes; disable sandbox (required inside Docker/Podman)
RUN echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf && \
    echo "sandbox = false" >> /etc/nix/nix.conf

# Create the user. The home directory stays root-owned until activation is done:
# activation runs as root, and Nix warns and ignores $HOME when it is owned by
# another user. Home Manager also needs a profiles directory to already exist.
RUN echo "thomaseckert:x:1000:1000::/home/thomaseckert:/bin/sh" >> /etc/passwd && \
    echo "thomaseckert:x:1000:" >> /etc/group && \
    mkdir -p /home/thomaseckert/.local/state/nix/profiles

# Copy dotfiles
COPY . /dotfiles

# Build the home-manager activation package and apply it to the user's home.
# Garbage collection must happen in this same step: build-only store paths
# (compilers, flake sources) would otherwise stay in this layer for good. The
# activated generation stays alive through its Home Manager profile and gcroots.
RUN cd /dotfiles && \
    nix build .#homeConfigurations."thomaseckert@linux".activationPackage && \
    HOME=/home/thomaseckert \
    USER=thomaseckert \
    ./result/activate && \
    rm result && \
    nix-collect-garbage && \
    rm -rf /root/.cache/nix && \
    chown -R thomaseckert:thomaseckert /home/thomaseckert

USER thomaseckert
WORKDIR /home/thomaseckert

ENV HOME=/home/thomaseckert
ENV USER=thomaseckert
ENV PATH=/home/thomaseckert/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH

CMD ["/home/thomaseckert/.nix-profile/bin/zsh"]
