# Claude Code status line. Packaged by nix/home/claude.nix with
# writeShellApplication, which adds the shebang, `set -euo pipefail` and puts
# jq, git and coreutils on PATH.
#
# Claude Code pipes session JSON on stdin and re-runs this after every assistant
# message (debounced to 300ms), so it must stay fast: no network, no slow CLIs
# such as gcloud. Schema: https://code.claude.com/docs/en/statusline.md
#
# Shows: directory • git branch and status • kube context • context used • model

input="$(cat)"
field() { jq -r "$1" <<<"$input"; }

dir="$(field '.workspace.current_dir // .cwd // empty')"
model="$(field '.model.display_name // "Claude"')"
# Null before the first API call and right after /compact.
used="$(field '.context_window.used_percentage // empty | floor')"

# Catppuccin Mocha, matching the terminal theme
c() { printf '\033[38;2;%sm%s\033[0m' "$1" "$2"; }
MAUVE='203;166;247'  LAVENDER='180;190;254'
GREEN='166;227;161'  YELLOW='249;226;175'    RED='243;139;168'
PEACH='250;179;135'  BLUE='137;180;250'      TEAL='148;226;213'
DIM='108;112;134'

segments=()

if [[ -n "$dir" ]]; then
  segments+=("$(c "$MAUVE" "${dir/#"$HOME"/\~}")")
fi

# --no-optional-locks: never take index.lock, so this can't collide with a git
# command Claude is running at the same moment.
if [[ -n "$dir" ]] && git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
  g=(git --no-optional-locks -C "$dir")
  branch="$("${g[@]}" symbolic-ref --short HEAD 2>/dev/null || "${g[@]}" rev-parse --short HEAD)"
  staged=0 changed=0 untracked=0 ahead=0 behind=0
  while IFS= read -r line; do
    case "${line:0:2}" in
      "##")
        [[ "$line" =~ ahead\ ([0-9]+) ]] && ahead="${BASH_REMATCH[1]}"
        [[ "$line" =~ behind\ ([0-9]+) ]] && behind="${BASH_REMATCH[1]}"
        ;;
      "??") untracked=$((untracked + 1)) ;;
      *)
        [[ "${line:0:1}" != " " ]] && staged=$((staged + 1))
        [[ "${line:1:1}" != " " ]] && changed=$((changed + 1))
        ;;
    esac
  done < <("${g[@]}" status --porcelain=v1 -b 2>/dev/null)

  s="$(c "$LAVENDER" "$branch")"
  (( staged > 0 ))    && s+="$(c "$GREEN" " +$staged")"
  (( changed > 0 ))   && s+="$(c "$YELLOW" " ~$changed")"
  (( untracked > 0 )) && s+="$(c "$DIM" " ?$untracked")"
  (( ahead > 0 ))     && s+="$(c "$PEACH" " ↑$ahead")"
  (( behind > 0 ))    && s+="$(c "$PEACH" " ↓$behind")"
  segments+=("$s")
fi

# kubectl isn't a runtime input: show the context only where it's installed.
if command -v kubectl >/dev/null 2>&1; then
  ctx="$(kubectl config current-context 2>/dev/null || true)"
  [[ -n "$ctx" ]] && segments+=("$(c "$BLUE" "☸ ${ctx#gke_}")")
fi

if [[ -n "$used" ]]; then
  if   (( used >= 75 )); then col="$RED"
  elif (( used >= 50 )); then col="$YELLOW"
  else col="$DIM"; fi
  segments+=("$(c "$col" "${used}% context")")
fi

segments+=("$(c "$TEAL" "$model")")

sep="$(c "$DIM" " • ")"
out="${segments[0]}"
for s in "${segments[@]:1}"; do out+="$sep$s"; done
printf '%s\n' "$out"
