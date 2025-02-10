DISABLE_UPDATE_PROMPT="true"
ENABLE_CORRECTION="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
  export VISUAL='vim'
else
  export EDITOR='nvim'
  export VISUAL='nvim'
fi

export ZSH="$HOME/.oh-my-zsh"

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

alias k=kubectl
alias v=nvim
alias z="zellij"
alias py=python3
alias python=python3
alias md=mkdir
alias mcd="mkdir $_ && cd $_"
alias venv="source .venv/bin/activate"
alias cat="bat"
alias fgi="$HOME/Scripts/fetch-gitignore.sh"
alias csl="$HOME/Repos/consul"
alias cks="$HOME/Repos/consul-k8s"
alias cksr="$HOME/Repos/consul-k8s-releases"
alias hc="$HOME/go/src/github.com/hashicorp"
alias scr="$HOME/Scripts/scripts"
alias tt="teamtime ~/.teammembers.json"
alias td="$HOME/Scripts/scripts/print-md.sh $CONSUL_TEAM"
alias kbb="kubectl run -i --tty --rm debug --image=busybox --restart=Never -- sh"
alias gs="git status"
alias zrc="$EDITOR $HOME/.zshrc"
alias dockert=docker # I always mess this up because of my last name.
alias clera="clear"

unsetopt correct_all

export GOPATH=$HOME/go

export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git/'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export PATH=/opt/homebrew/bin:$HOME/.local/bin/:/Applications/GoLand.app/Contents/MacOS:$HOME/lsp/bin:$GOROOT/bin:$GOPATH/bin:~/repos/dotfiles/scripts/:$PATH
export NVM_DIR=~/.nvm
export BAT_THEME=base16
export XDG_CONFIG_HOME=$HOME/.config

[[ $commands[kubectl] ]] && source <(kubectl completion zsh)
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
if [ -f '/Users/thomaseckert/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/thomaseckert/google-cloud-sdk/path.zsh.inc'; fi
if [ -f '/Users/thomaseckert/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/thomaseckert/google-cloud-sdk/completion.zsh.inc'; fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Color shortcuts
RED=$fg[red]
YELLOW=$fg[yellow]
GREEN=$fg[green]
WHITE=$fg[white]
BLUE=$fg[blue]
RED_BOLD=$fg_bold[red]
YELLOW_BOLD=$fg_bold[yellow]
GREEN_BOLD=$fg_bold[green]
WHITE_BOLD=$fg_bold[white]
BLUE_BOLD=$fg_bold[blue]
RESET_COLOR=$reset_color

# Format for git_prompt_info()
ZSH_THEME_GIT_PROMPT_PREFIX=""
ZSH_THEME_GIT_PROMPT_SUFFIX=""

# Format for parse_git_dirty()
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$RED%}(*)"
ZSH_THEME_GIT_PROMPT_CLEAN=""

# Format for git_prompt_status()
ZSH_THEME_GIT_PROMPT_UNMERGED=" %{$RED%}unmerged"
ZSH_THEME_GIT_PROMPT_DELETED=" %{$RED%}deleted"
ZSH_THEME_GIT_PROMPT_RENAMED=" %{$YELLOW%}renamed"
ZSH_THEME_GIT_PROMPT_MODIFIED=" %{$YELLOW%}modified"
ZSH_THEME_GIT_PROMPT_ADDED=" %{$GREEN%}added"
ZSH_THEME_GIT_PROMPT_UNTRACKED=" %{$WHITE%}untracked"

# Format for git_prompt_ahead()
ZSH_THEME_GIT_PROMPT_AHEAD=" %{$RED%}(!)"

# Format for git_prompt_long_sha() and git_prompt_short_sha()
ZSH_THEME_GIT_PROMPT_SHA_BEFORE=" %{$WHITE%}[%{$YELLOW%}"
ZSH_THEME_GIT_PROMPT_SHA_AFTER="%{$WHITE%}]"

LS_COLORS='no=0;97:fi=0;34:di=1;97:ln=1;97:pi=0;32:ex=1;35:ow=1;97'

# Prompt format
PROMPT='%{$YELLOW%}%~%u$(parse_git_dirty)$(git_prompt_ahead)%{$RESET_COLOR%}
%{$BLUE%}|>%{$RESET_COLOR%} '
RPROMPT='%{$GREEN_BOLD%}$(git_current_branch)$(git_prompt_short_sha)$(git_prompt_status)%{$RESET_COLOR%}'

bindkey -v
autoload -z edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

if [ -f '/Users/thomaseckert/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/thomaseckert/Downloads/google-cloud-sdk/path.zsh.inc'; fi
if [ -f '/Users/thomaseckert/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/thomaseckert/Downloads/google-cloud-sdk/completion.zsh.inc'; fi
export PATH="/usr/local/opt/curl/bin:$PATH"

ZELLIJ_AUTO_ATTACH="true"
eval "$(zellij setup --generate-auto-start zsh)"
eval "$(atuin init zsh)"
