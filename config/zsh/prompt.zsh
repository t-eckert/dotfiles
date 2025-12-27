#!/usr/bin/env zsh
# Rich terminal prompt with dense information display
# Inspired by nix-prompt's modular design

# ============================================================================
# COLOR PALETTE - Catppuccin Mocha (muted pastels)
# ============================================================================

# Core colors
PROMPT_LAVENDER='#b4befe'
PROMPT_BLUE='#89b4fa'
PROMPT_SAPPHIRE='#74c7ec'
PROMPT_SKY='#89dceb'
PROMPT_TEAL='#94e2d5'
PROMPT_GREEN='#a6e3a1'
PROMPT_YELLOW='#f9e2af'
PROMPT_PEACH='#fab387'
PROMPT_MAROON='#eba0ac'
PROMPT_RED='#f38ba8'
PROMPT_MAUVE='#cba6f7'
PROMPT_PINK='#f5c2e7'
PROMPT_FLAMINGO='#f2cdcd'
PROMPT_ROSEWATER='#f5e0dc'
PROMPT_TEXT='#cdd6f4'
PROMPT_SUBTEXT1='#bac2de'
PROMPT_SUBTEXT0='#a6adc8'
PROMPT_OVERLAY2='#9399b2'
PROMPT_OVERLAY1='#7f849c'
PROMPT_OVERLAY0='#6c7086'
PROMPT_SURFACE2='#585b70'
PROMPT_SURFACE1='#45475a'
PROMPT_SURFACE0='#313244'
PROMPT_BASE='#1e1e2e'
PROMPT_MANTLE='#181825'
PROMPT_CRUST='#11111b'

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Convert hex to ANSI 24-bit color
hex_to_ansi() {
  local hex="${1#\#}"
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  echo "\033[38;2;${r};${g};${b}m"
}

# Colorize text with hex color
colorize() {
  local color="$1"
  local text="$2"
  local ansi_color=$(hex_to_ansi "$color")
  echo "${ansi_color}${text}\033[0m"
}

# ============================================================================
# EXECUTION TIME TRACKING
# ============================================================================

preexec() {
  PROMPT_EXEC_START=$SECONDS
}

precmd() {
  local exec_time=0
  if [[ -n "$PROMPT_EXEC_START" ]]; then
    exec_time=$((SECONDS - PROMPT_EXEC_START))
    unset PROMPT_EXEC_START
  fi
  PROMPT_EXEC_TIME=$exec_time
  PROMPT_LAST_EXIT=$?
}

# ============================================================================
# CONTEXT DETECTION FUNCTIONS
# ============================================================================

# Git status (dense format)
prompt_git() {
  # Check if in git repo
  git rev-parse --git-dir >/dev/null 2>&1 || return

  local branch_icon=""
  local branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

  # Git status parsing
  local ahead=0 behind=0 staged=0 modified=0 deleted=0 untracked=0 conflicted=0
  local is_dirty=false

  # Parse git status porcelain
  while IFS= read -r line; do
    local git_status="${line:0:2}"
    case "$git_status" in
      "##")
        # Branch tracking info
        if [[ "$line" =~ ahead\ ([0-9]+) ]]; then
          ahead="${match[1]}"
        fi
        if [[ "$line" =~ behind\ ([0-9]+) ]]; then
          behind="${match[1]}"
        fi
        ;;
      "??") ((untracked++)); is_dirty=true ;;
      "UU"|"AA"|"DD") ((conflicted++)); is_dirty=true ;;
      *)
        [[ "${git_status:0:1}" != " " && "${git_status:0:1}" != "?" ]] && ((staged++))
        [[ "${git_status:1:1}" == "M" ]] && ((modified++)) && is_dirty=true
        [[ "${git_status:1:1}" == "D" ]] && ((deleted++)) && is_dirty=true
        ;;
    esac
  done < <(git status --porcelain=v1 -b 2>/dev/null)

  # Build git string
  local git_str=""
  git_str+=$(colorize "$PROMPT_MAUVE" "$branch_icon")
  git_str+=" "
  git_str+=$(colorize "$PROMPT_LAVENDER" "$branch")

  # Dirty indicator
  if [[ "$is_dirty" == true ]]; then
    git_str+=$(colorize "$PROMPT_YELLOW" "✱")
  fi

  # Staged changes
  [[ $staged -gt 0 ]] && git_str+=$(colorize "$PROMPT_GREEN" "+$staged")

  # Modified files
  [[ $modified -gt 0 ]] && git_str+=$(colorize "$PROMPT_YELLOW" "~$modified")

  # Deleted files
  [[ $deleted -gt 0 ]] && git_str+=$(colorize "$PROMPT_RED" "-$deleted")

  # Untracked files
  [[ $untracked -gt 0 ]] && git_str+=$(colorize "$PROMPT_OVERLAY2" "?$untracked")

  # Conflicted files
  [[ $conflicted -gt 0 ]] && git_str+=$(colorize "$PROMPT_RED" "!$conflicted")

  # Ahead/behind
  [[ $ahead -gt 0 ]] && git_str+=$(colorize "$PROMPT_PEACH" "↑$ahead")
  [[ $behind -gt 0 ]] && git_str+=$(colorize "$PROMPT_PEACH" "↓$behind")

  echo "$git_str"
}

# Kubernetes context
prompt_k8s() {
  command -v kubectl >/dev/null 2>&1 || return

  local context=$(kubectl config current-context 2>/dev/null)
  [[ -z "$context" ]] && return

  # Shorten common context names
  context="${context#gke_}"
  context="${context#arn:aws:eks:}"

  local k8s_icon="☸"
  echo "$(colorize "$PROMPT_SAPPHIRE" "$k8s_icon") $(colorize "$PROMPT_BLUE" "$context")"
}

# Rust project detection
prompt_rust() {
  [[ -f "Cargo.toml" ]] || return

  local rust_icon="🦀"
  local project=""

  # Try to get project name from Cargo.toml
  if command -v grep >/dev/null 2>&1; then
    project=$(grep '^name' Cargo.toml 2>/dev/null | head -1 | cut -d'"' -f2)
  fi

  if [[ -n "$project" ]]; then
    echo "$(colorize "$PROMPT_PEACH" "$rust_icon") $(colorize "$PROMPT_ROSEWATER" "$project")"
  else
    echo "$(colorize "$PROMPT_PEACH" "$rust_icon") $(colorize "$PROMPT_ROSEWATER" "cargo")"
  fi
}

# Go module detection
prompt_go() {
  [[ -f "go.mod" ]] || return

  local go_icon=""
  local module=""

  # Get module name from go.mod
  if command -v awk >/dev/null 2>&1; then
    module=$(awk '/^module/ {print $2}' go.mod 2>/dev/null | tail -1)
    # Get last component of module path
    module="${module##*/}"
  fi

  if [[ -n "$module" ]]; then
    echo "$(colorize "$PROMPT_SAPPHIRE" "$go_icon") $(colorize "$PROMPT_SKY" "$module")"
  else
    echo "$(colorize "$PROMPT_SAPPHIRE" "$go_icon") $(colorize "$PROMPT_SKY" "go")"
  fi
}

# Python virtual environment
prompt_python() {
  [[ -n "$VIRTUAL_ENV" ]] || return

  local py_icon=""
  local venv_name=$(basename "$VIRTUAL_ENV")

  echo "$(colorize "$PROMPT_YELLOW" "$py_icon") $(colorize "$PROMPT_PEACH" "$venv_name")"
}

# Cloud context (AWS/GCP/Azure)
prompt_cloud() {
  local cloud_str=""

  # AWS
  if [[ -n "$AWS_PROFILE" ]]; then
    cloud_str+="$(colorize "$PROMPT_PEACH" "") $(colorize "$PROMPT_FLAMINGO" "$AWS_PROFILE")"
  fi

  # GCP
  if command -v gcloud >/dev/null 2>&1; then
    local gcp_project=$(gcloud config get-value project 2>/dev/null)
    if [[ -n "$gcp_project" && -z "$cloud_str" ]]; then
      cloud_str+="$(colorize "$PROMPT_BLUE" "󱇶") $(colorize "$PROMPT_SAPPHIRE" "$gcp_project")"
    fi
  fi

  echo "$cloud_str"
}

# ============================================================================
# PROMPT ASSEMBLY
# ============================================================================

build_status_line() {
  local segments=()

  # Directory (always show)
  local dir_icon=""
  local current_dir="%~"
  segments+=("$(colorize "$PROMPT_MAUVE" "$dir_icon") %F{$PROMPT_TEXT}${current_dir}%f")

  # Git (priority 1)
  local git_info=$(prompt_git)
  [[ -n "$git_info" ]] && segments+=("$git_info")

  # Kubernetes (priority 2)
  local k8s_info=$(prompt_k8s)
  [[ -n "$k8s_info" ]] && segments+=("$k8s_info")

  # Rust (priority 3)
  local rust_info=$(prompt_rust)
  [[ -n "$rust_info" ]] && segments+=("$rust_info")

  # Go (priority 4)
  local go_info=$(prompt_go)
  [[ -n "$go_info" ]] && segments+=("$go_info")

  # Python (priority 5)
  local python_info=$(prompt_python)
  [[ -n "$python_info" ]] && segments+=("$python_info")

  # Cloud (priority 6)
  local cloud_info=$(prompt_cloud)
  [[ -n "$cloud_info" ]] && segments+=("$cloud_info")

  # Execution time (if > 2 seconds)
  if [[ ${PROMPT_EXEC_TIME:-0} -gt 2 ]]; then
    segments+=("$(colorize "$PROMPT_OVERLAY2" "⏱") $(colorize "$PROMPT_SUBTEXT0" "${PROMPT_EXEC_TIME}s")")
  fi

  # Exit status
  if [[ ${PROMPT_LAST_EXIT:-0} -eq 0 ]]; then
    segments+=("$(colorize "$PROMPT_GREEN" "✓")")
  else
    segments+=("$(colorize "$PROMPT_RED" "✗") $(colorize "$PROMPT_MAROON" "${PROMPT_LAST_EXIT}")")
  fi

  # Join segments with separator
  local separator=" $(colorize "$PROMPT_SURFACE2" "•") "
  local status_line="${(j:$separator:)segments}"

  echo "$status_line"
}

# Build the actual prompt
setopt PROMPT_SUBST
PROMPT='$(build_status_line)
$(colorize "$PROMPT_LAVENDER" "❯") '

# Remove right prompt
RPROMPT=''
