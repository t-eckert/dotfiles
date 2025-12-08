# MacOS-specific PATH and environment settings

# Homebrew paths
export PATH=/opt/homebrew/bin:$PATH
export PATH=/usr/local/bin:$PATH

# MacOS application paths
export PATH=/Applications/GoLand.app/Contents/MacOS:$PATH

# MacOS-specific curl (if installed via Homebrew)
[ -d "/usr/local/opt/curl/bin" ] && export PATH="/usr/local/opt/curl/bin:$PATH"

# MacOS-specific settings
export BROWSER=open
