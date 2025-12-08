# Linux/Debian-specific PATH and environment settings

# Go (if installed to /usr/local/go)
export PATH=/usr/local/go/bin:$PATH

# Local bin
export PATH=$HOME/.local/bin:$PATH

# Linux-specific settings
export BROWSER=xdg-open
