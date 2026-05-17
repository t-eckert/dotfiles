#!/usr/bin/env bash
# Rich status line for Claude Code - matches ZSH prompt style
# Based on config/zsh/prompt.zsh with Catppuccin Mocha colors

# ============================================================================
# COLOR PALETTE - Catppuccin Mocha (24-bit ANSI)
# ============================================================================

hex_to_ansi() {
  local hex="${1#\#}"
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  echo -en "\033[38;2;${r};${g};${b}m"
}

colorize() {
  local color="$1"
  local text="$2"
  echo -n "$(hex_to_ansi "$color")${text}\033[0m"
}

# Core colors
LAVENDER='#b4befe'
BLUE='#89b4fa'
SAPPHIRE='#74c7ec'
SKY='#89dceb'
TEAL='#94e2d5'
GREEN='#a6e3a1'
YELLOW='#f9e2af'
PEACH='#fab387'
MAROON='#eba0ac'
RED='#f38ba8'
MAUVE='#cba6f7'
PINK='#f5c2e7'
FLAMINGO='#f2cdcd'
ROSEWATER='#f5e0dc'
TEXT='#cdd6f4'
SUBTEXT1='#bac2de'
SUBTEXT0='#a6adc8'
OVERLAY2='#9399b2'
OVERLAY1='#7f849c'
OVERLAY0='#6c7086'
SURFACE2='#585b70'
SURFACE1='#45475a'
SURFACE0='#313244'

# ============================================================================
# PARSE CLAUDE CODE CONTEXT
# ============================================================================

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // "~"')
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
token_used=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
token_budget=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')

# Shorten home directory
cwd="${cwd/#$HOME/~}"

# ============================================================================
# CONTEXT DETECTION FUNCTIONS
# ============================================================================

prompt_git() {
  git rev-parse --git-dir >/dev/null 2>&1 || return

  local branch_icon=""
  local branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

  # Git status parsing
  local ahead=0 behind=0 staged=0 modified=0 deleted=0 untracked=0 conflicted=0
  local is_dirty=false

  while IFS= read -r line; do
    local status="${line:0:2}"
    case "$status" in
      "##")
        if [[ "$line" =~ ahead\ ([0-9]+) ]]; then
          ahead="${BASH_REMATCH[1]}"
        fi
        if [[ "$line" =~ behind\ ([0-9]+) ]]; then
          behind="${BASH_REMATCH[1]}"
        fi
        ;;
      "??") ((untracked++)); is_dirty=true ;;
      "UU"|"AA"|"DD") ((conflicted++)); is_dirty=true ;;
      *)
        [[ "${status:0:1}" != " " && "${status:0:1}" != "?" ]] && ((staged++))
        [[ "${status:1:1}" == "M" ]] && ((modified++)) && is_dirty=true
        [[ "${status:1:1}" == "D" ]] && ((deleted++)) && is_dirty=true
        ;;
    esac
  done < <(git status --porcelain=v1 -b 2>/dev/null)

  # Build git string
  local git_str=""
  git_str+=$(colorize "$MAUVE" "$branch_icon")
  git_str+=" "
  git_str+=$(colorize "$LAVENDER" "$branch")

  # Dirty indicator
  [[ "$is_dirty" == true ]] && git_str+=$(colorize "$YELLOW" "✱")

  # Status indicators
  [[ $staged -gt 0 ]] && git_str+=$(colorize "$GREEN" "+$staged")
  [[ $modified -gt 0 ]] && git_str+=$(colorize "$YELLOW" "~$modified")
  [[ $deleted -gt 0 ]] && git_str+=$(colorize "$RED" "-$deleted")
  [[ $untracked -gt 0 ]] && git_str+=$(colorize "$OVERLAY2" "?$untracked")
  [[ $conflicted -gt 0 ]] && git_str+=$(colorize "$RED" "!$conflicted")
  [[ $ahead -gt 0 ]] && git_str+=$(colorize "$PEACH" "↑$ahead")
  [[ $behind -gt 0 ]] && git_str+=$(colorize "$PEACH" "↓$behind")

  echo -n "$git_str"
}

prompt_k8s() {
  command -v kubectl >/dev/null 2>&1 || return

  local context=$(kubectl config current-context 2>/dev/null)
  [[ -z "$context" ]] && return

  # Shorten common context names
  context="${context#gke_}"
  context="${context#arn:aws:eks:}"

  local k8s_icon="☸"
  echo -n "$(colorize "$SAPPHIRE" "$k8s_icon") $(colorize "$BLUE" "$context")"
}

prompt_rust() {
  [[ -f "Cargo.toml" ]] || return

  local rust_icon="🦀"
  local project=$(grep '^name' Cargo.toml 2>/dev/null | head -1 | cut -d'"' -f2)

  if [[ -n "$project" ]]; then
    echo -n "$(colorize "$PEACH" "$rust_icon") $(colorize "$ROSEWATER" "$project")"
  else
    echo -n "$(colorize "$PEACH" "$rust_icon") $(colorize "$ROSEWATER" "cargo")"
  fi
}

prompt_go() {
  [[ -f "go.mod" ]] || return

  local go_icon=""
  local module=$(awk '/^module/ {print $2}' go.mod 2>/dev/null | tail -1)
  module="${module##*/}"

  if [[ -n "$module" ]]; then
    echo -n "$(colorize "$SAPPHIRE" "$go_icon") $(colorize "$SKY" "$module")"
  else
    echo -n "$(colorize "$SAPPHIRE" "$go_icon") $(colorize "$SKY" "go")"
  fi
}

prompt_python() {
  [[ -n "$VIRTUAL_ENV" ]] || return

  local py_icon=""
  local venv_name=$(basename "$VIRTUAL_ENV")

  echo -n "$(colorize "$YELLOW" "$py_icon") $(colorize "$PEACH" "$venv_name")"
}

prompt_cloud() {
  local cloud_str=""

  # AWS
  if [[ -n "$AWS_PROFILE" ]]; then
    cloud_str+="$(colorize "$PEACH" "") $(colorize "$FLAMINGO" "$AWS_PROFILE")"
  fi

  # GCP
  if command -v gcloud >/dev/null 2>&1; then
    local gcp_project=$(gcloud config get-value project 2>/dev/null)
    if [[ -n "$gcp_project" && -z "$cloud_str" ]]; then
      cloud_str+="$(colorize "$BLUE" "󱇶") $(colorize "$SAPPHIRE" "$gcp_project")"
    fi
  fi

  echo -n "$cloud_str"
}

# ============================================================================
# BUILD STATUS LINE
# ============================================================================

segments=()

# Directory (always show)
dir_icon=""
segments+=("$(colorize "$MAUVE" "$dir_icon") $(colorize "$TEXT" "$cwd")")

# Git (priority 1)
git_info=$(prompt_git)
[[ -n "$git_info" ]] && segments+=("$git_info")

# Kubernetes (priority 2)
k8s_info=$(prompt_k8s)
[[ -n "$k8s_info" ]] && segments+=("$k8s_info")

# Rust (priority 3)
rust_info=$(prompt_rust)
[[ -n "$rust_info" ]] && segments+=("$rust_info")

# Go (priority 4)
go_info=$(prompt_go)
[[ -n "$go_info" ]] && segments+=("$go_info")

# Python (priority 5)
python_info=$(prompt_python)
[[ -n "$python_info" ]] && segments+=("$python_info")

# Cloud (priority 6)
cloud_info=$(prompt_cloud)
[[ -n "$cloud_info" ]] && segments+=("$cloud_info")

# Token usage
if [[ "$token_used" != "null" && "$token_budget" != "null" && "$token_budget" -gt 0 ]]; then
  percent=$((token_used * 100 / token_budget))
  if [[ $percent -gt 75 ]]; then
    token_color="$RED"
  elif [[ $percent -gt 50 ]]; then
    token_color="$YELLOW"
  else
    token_color="$OVERLAY2"
  fi
  segments+=("$(colorize "$token_color" "⏱") $(colorize "$SUBTEXT0" "${percent}%")")
fi

# Model indicator
segments+=("$(colorize "$GREEN" "◆") $(colorize "$TEAL" "$model")")

# Join segments with separator
separator=" $(colorize "$SURFACE2" "•") "
status_line=""
for i in "${!segments[@]}"; do
  if [[ $i -eq 0 ]]; then
    status_line="${segments[$i]}"
  else
    status_line+="${separator}${segments[$i]}"
  fi
done

echo "$status_line"
