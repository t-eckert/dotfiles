# Multi-stage Debian-based development environment for dotfiles
# Build: docker build -t dotfiles-dev -f Containerfile .
# Run: docker compose run --rm devenv

# =============================================================================
# Stage 1: Base System Setup
# =============================================================================
FROM debian:bookworm-slim AS base

# Install core dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    gnupg2 \
    ca-certificates \
    lsb-release \
    sudo \
    locales \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

# Setup locale
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Create user with configurable UID/GID (default 1000)
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# =============================================================================
# Stage 2: External Repositories
# =============================================================================
FROM base AS repos

# Copy repo setup script
COPY packages/debian-external-repos.sh /tmp/
COPY lib/logger.sh /tmp/lib/

RUN chmod +x /tmp/debian-external-repos.sh && \
    mkdir -p /tmp/lib && \
    /tmp/debian-external-repos.sh && \
    apt-get update

# =============================================================================
# Stage 3: Package Installation
# =============================================================================
FROM repos AS packages

# Copy package manifest
COPY packages/debian.manifest /tmp/

# Install packages from manifest
RUN apt-get install -y \
    # Core dependencies
    curl wget git stow build-essential software-properties-common \
    gnupg2 ca-certificates lsb-release sudo locales \
    # Dev tools
    autoconf autoconf-archive automake ccache cmake ctags gettext pkg-config nasm \
    # CLI tools
    neovim ripgrep fzf bat jq yq tree watch nmap ffmpeg \
    # Build tools
    gcc llvm ninja-build protobuf-compiler \
    # Version control
    git \
    # Utilities
    virtualenv luarocks \
    # External repo packages
    gh docker-ce docker-ce-cli containerd.io kubectl terraform helm \
    nodejs npm tailscale \
    && rm -rf /var/lib/apt/lists/*

# Add user to docker group (for Docker-in-Docker)
ARG USERNAME=dev
RUN usermod -aG docker $USERNAME || true

# Install Oh My Zsh for user
USER $USERNAME
WORKDIR /home/$USERNAME

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install zsh-autosuggestions
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# Switch back to root for remaining setup
USER root

# Install zsh system-wide
RUN apt-get update && apt-get install -y zsh && rm -rf /var/lib/apt/lists/*

# =============================================================================
# Stage 4: Language Toolchains
# =============================================================================
FROM packages AS toolchains

# Install Go (specific version for reproducibility)
ARG GO_VERSION=1.24.0
RUN wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    rm -rf /usr/local/go && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz

ENV PATH=/usr/local/go/bin:$PATH
ARG USERNAME=dev
ENV GOPATH=/home/$USERNAME/go
ENV PATH=$GOPATH/bin:$PATH

# Install Yarn globally
RUN npm install -g yarn

# =============================================================================
# Stage 5: Dotfiles Setup
# =============================================================================
FROM toolchains AS dotfiles

ARG USERNAME=dev
WORKDIR /tmp/dotfiles

# Copy dotfiles repo (optimize layer caching by copying in order of change frequency)
# 1. Go module files (change rarely)
COPY --chown=$USERNAME:$USERNAME go.mod go.sum ./
USER $USERNAME
RUN go mod download

# 2. Tools source code (change occasionally)
USER root
COPY --chown=$USERNAME:$USERNAME tools/ ./tools/
USER $USERNAME
RUN go install ./tools/*

# 3. Installation scripts and libraries
USER root
COPY --chown=$USERNAME:$USERNAME lib/ ./lib/
COPY --chown=$USERNAME:$USERNAME packages/ ./packages/
COPY --chown=$USERNAME:$USERNAME install-debian.sh install.sh ./

# 4. Config files (change most frequently)
COPY --chown=$USERNAME:$USERNAME config/ ./config/
COPY --chown=$USERNAME:$USERNAME config-variants/ ./config-variants/
COPY --chown=$USERNAME:$USERNAME .zshrc .gitconfig .editorconfig ./
COPY --chown=$USERNAME:$USERNAME Brewfile ./

# Run dotfiles installation as user
USER $USERNAME
RUN chmod +x ./install-debian.sh && \
    ./install-debian.sh || true

# Setup persistent volume mount points
RUN mkdir -p \
    /home/$USERNAME/.local/share/nvim \
    /home/$USERNAME/.local/share/atuin \
    /home/$USERNAME/.config/zsh_history \
    /home/$USERNAME/.cache \
    /home/$USERNAME/go/pkg

WORKDIR /workspace

# Default shell and environment
ENV SHELL=/bin/zsh
ENV TERM=xterm-256color
ENV COLORTERM=truecolor

CMD ["/bin/zsh"]
