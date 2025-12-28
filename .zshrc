DISABLE_UPDATE_PROMPT="true" # Always upgrade if there is new Oh My Zsh
ENABLE_CORRECTION="true" # Enable command correction
DISABLE_UNTRACKED_FILES_DIRTY="true" # Disable untracked files in git status

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
  export VISUAL='vim'
else
  export EDITOR='nvim'
  export VISUAL='nvim'
fi

# Oh My Zsh Plugins

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""  # Disable Oh My Zsh themes (using Starship instead)

plugins=(
  1password
  aliases
  docker
  git
  git-auto-fetch
  gitignore
  gh
  golang
  helm
  kubectl
  node
  python
  web-search
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

# Aliases

alias k=kubectl
alias v=nvim
alias z="zellij"
alias py=python3
alias python=python3
alias md=mkdir
alias mcd="mkdir $_ && cd $_"
alias venv="source .venv/bin/activate"
alias cat="bat"
alias kbb="kubectl run -i --tty --rm debug --image=busybox --restart=Never -- sh"
alias gs="git status"
alias zrc="$EDITOR $HOME/.zshrc"
alias dockert=docker # I always mess this up because of my last name.
alias clera="clear"
alias tree="tree --dirsfirst"
alias mvlatest='mv "$(ls -t ~/Downloads/* | head -n1)" .'

# Quick access to Repos

alias ft="cd ~/Repos/github.com/t-eckert/field-theories/"

unsetopt correct_all

# Environment Variables

export GOPATH=$HOME/go
export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git/'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export PATH=/opt/homebrew/bin:$HOME/.local/bin/:/Applications/GoLand.app/Contents/MacOS:$HOME/lsp/bin:$GOROOT/bin:$GOPATH/bin:~/repos/dotfiles/scripts/:$PATH
export NVM_DIR=~/.nvm
export BAT_THEME=base16
export XDG_CONFIG_HOME=$HOME/.config

# Lazy load kubectl completion for faster shell startup
if [[ $commands[kubectl] ]]; then
  kubectl() {
    if ! type __start_kubectl >/dev/null 2>&1; then
      source <(command kubectl completion zsh)
    fi
    command kubectl "$@"
  }
fi

# NVM
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Google Cloud SDK (check multiple possible locations)
for gcloud_path in "$HOME/google-cloud-sdk" "$HOME/Downloads/google-cloud-sdk" "/usr/local/Caskroom/google-cloud-sdk"; do
  if [ -f "$gcloud_path/path.zsh.inc" ]; then
    source "$gcloud_path/path.zsh.inc"
    [ -f "$gcloud_path/completion.zsh.inc" ] && source "$gcloud_path/completion.zsh.inc"
    break
  fi
done

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

LS_COLORS='no=0;97:fi=0;34:di=1;97:ln=1;97:pi=0;32:ex=1;35:ow=1;97'

# Starship prompt
eval "$(starship init zsh)"

bindkey -v
autoload -z edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

# Add curl to PATH if installed via Homebrew
[ -d "/usr/local/opt/curl/bin" ] && export PATH="/usr/local/opt/curl/bin:$PATH"

# Zellij auto-start
eval "$(zellij setup --generate-auto-start zsh)"

# Atuin shell history
eval "$(atuin init zsh)"
