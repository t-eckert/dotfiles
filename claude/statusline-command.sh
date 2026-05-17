#!/bin/bash
# Claude Code Status Line - Inspired by Starship Catppuccin Mocha theme
# This script receives JSON input via stdin with Claude Code context

# Read JSON input
input=$(cat)

# Extract context from JSON
cwd=$(echo "$input" | jq -r '.cwd')
model_name=$(echo "$input" | jq -r '.model.display_name // empty')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Catppuccin Mocha Color Palette (using ANSI escape codes)
# Note: These will be displayed dimmed in the status line
MAUVE="\033[38;2;203;166;247m"      # Directory
LAVENDER="\033[38;2;180;190;254m"   # Git branch, character
RED="\033[38;2;243;139;168m"        # Error, conflicts
PEACH="\033[38;2;250;179;135m"      # Ahead/behind
YELLOW="\033[38;2;249;226;175m"     # Modified, stashed
GREEN="\033[38;2;166;227;161m"      # Staged, success
BLUE="\033[38;2;137;180;250m"       # General info
SAPPHIRE="\033[38;2;116;199;236m"   # Kubernetes
OVERLAY2="\033[38;2;147;153;178m"   # Untracked
OVERLAY1="\033[38;2;127;132;156m"   # Time
TEXT="\033[38;2;205;214;244m"       # Git status
RESET="\033[0m"

# Change to the working directory
cd "$cwd" 2>/dev/null || exit 0

# Output string
output=""

# Directory (with substitutions like Starship)
display_dir="$cwd"
display_dir="${display_dir/#$HOME\/Repos\/github.com\/t-eckert/~}"
display_dir="${display_dir/#$HOME\/Repos\/github.com\/redpanda-data/ rp}"
display_dir="${display_dir/#$HOME/~}"
output+=$(printf "${MAUVE}${display_dir} ${RESET}")

# Git information (if in a git repository)
if git rev-parse --git-dir > /dev/null 2>&1; then
    # Branch name
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    output+=$(printf "${LAVENDER} ${branch} ${RESET}")
    
    # Git status (skip lock file issues)
    git_status=$(git --no-optional-locks status --porcelain 2>/dev/null)
    
    if [ -n "$git_status" ]; then
        # Count different types of changes
        modified=$(echo "$git_status" | grep -c '^ M' || true)
        staged=$(echo "$git_status" | grep -c '^[MARC]' || true)
        untracked=$(echo "$git_status" | grep -c '^??' || true)
        deleted=$(echo "$git_status" | grep -c '^ D' || true)
        
        status_output=""
        [ "$staged" -gt 0 ] && status_output+=$(printf "${GREEN}+${staged}${RESET} ")
        [ "$modified" -gt 0 ] && status_output+=$(printf "${YELLOW}~${modified}${RESET} ")
        [ "$untracked" -gt 0 ] && status_output+=$(printf "${OVERLAY2}?${untracked}${RESET} ")
        [ "$deleted" -gt 0 ] && status_output+=$(printf "${RED}-${deleted}${RESET} ")
        
        [ -n "$status_output" ] && output+=$(printf "${TEXT}${status_output}${RESET}")
    fi
    
    # Ahead/behind
    ahead=$(git rev-list @{u}..HEAD 2>/dev/null | wc -l | tr -d ' ')
    behind=$(git rev-list HEAD..@{u} 2>/dev/null | wc -l | tr -d ' ')
    
    if [ "$ahead" -gt 0 ] 2>/dev/null; then
        output+=$(printf "${PEACH}↑${ahead} ${RESET}")
    fi
    if [ "$behind" -gt 0 ] 2>/dev/null; then
        output+=$(printf "${PEACH}↓${behind} ${RESET}")
    fi
fi

# Context window usage (if available)
if [ -n "$remaining_pct" ] && [ "$remaining_pct" != "null" ]; then
    remaining_int=$(printf "%.0f" "$remaining_pct")
    
    # Color based on remaining percentage
    if [ "$remaining_int" -lt 10 ]; then
        ctx_color="$RED"
    elif [ "$remaining_int" -lt 25 ]; then
        ctx_color="$YELLOW"
    else
        ctx_color="$SAPPHIRE"
    fi
    
    output+=$(printf "${ctx_color}${remaining_int}%% ${RESET}")
fi

# Model name (abbreviated)
if [ -n "$model_name" ]; then
    model_short=$(echo "$model_name" | sed 's/Claude //' | sed 's/ Sonnet/S/' | sed 's/ Opus/O/' | sed 's/ Haiku/H/')
    output+=$(printf "${BLUE}${model_short} ${RESET}")
fi

# Vim mode indicator (if vim mode is enabled)
if [ -n "$vim_mode" ]; then
    if [ "$vim_mode" = "INSERT" ]; then
        output+=$(printf "${GREEN}I ${RESET}")
    elif [ "$vim_mode" = "NORMAL" ]; then
        output+=$(printf "${LAVENDER}N ${RESET}")
    fi
fi

# Print final output
printf "$output"
