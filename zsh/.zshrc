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
alias py=python3.9
alias python=python3
alias md=mkdir
alias mcd="mkdir $_ && cd $_"
alias venv="source .venv/bin/activate"
alias cat="bat"
alias fixtime="sudo hwclock -s" # For when WSL gets out of sync.
alias nl="nb log"
alias gogo=$GOPATH/src/github.com/
alias fgi="$HOME/Scripts/fetch-gitignore.sh"
alias csl="$HOME/go/src/github.com/hashicorp/consul"
alias cks="$HOME/go/src/github.com/hashicorp/consul-k8s"
alias ckscli="$HOME/go/src/github.com/hashicorp/consul-k8s/cli"
alias cksacc="$HOME/go/src/github.com/hashicorp/consul-k8s/acceptance"
alias ckscp="$HOME/go/src/github.com/hashicorp/consul-k8s/control-plane"
alias cksr="$HOME/go/src/github.com/hashicorp/consul-k8s-releases"
alias hc="$HOME/go/src/github.com/hashicorp"
alias scr="$HOME/Scripts/scripts"
alias tt="teamtime ~/.teammembers.json"
alias td="$HOME/Scripts/scripts/print-md.sh $CONSUL_TEAM"
alias kbb="kubectl run -i --tty --rm debug --image=busybox --restart=Never -- sh"
alias gs="git status"
alias zrc="$EDITOR $HOME/.zshrc"

unsetopt correct_all

export GOPATH=~/go
export GOROOT="/usr/local/Cellar/go/1.18.3/libexec"
export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git/'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export CONSUL_ENT_LICENSE="$(cat $HOME/.consul.dev.license)"
export CONSUL_LICENSE_FILE="$HOME/.consul.dev.license"
export CONSUL_LICENSE="$(cat $HOME/.consul.dev.license)"
export PATH=$GOROOT/bin:$GOPATH/bin:/Applications/GoLand.app/Contents/MacOS:$HOME/lsp/bin:$PATH
export NVM_DIR=~/.nvm

[[ $commands[kubectl] ]] && source <(kubectl completion zsh)
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
if [ -f '/Users/thomaseckert/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/thomaseckert/google-cloud-sdk/path.zsh.inc'; fi
if [ -f '/Users/thomaseckert/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/thomaseckert/google-cloud-sdk/completion.zsh.inc'; fi

hdelall () {
    helm ls --all --short | xargs -L1 helm delete
    kubectl patch crd/serviceintentions.consul.hashicorp.com -p '{"metadata":{"finalizers":[]}}' --type=merge
    kubectl delete --all jobs
    kubectl delete --all statefulsets
    kubectl delete --all daemonsets
    kubectl delete --all replicasets
    kubectl delete --all deployments
    kubectl delete --all services
    kubectl delete ns ns1
    kubectl delete ns ns2
    kubectl get all
}

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
%{$BLUE%}=>%{$RESET_COLOR%} '
RPROMPT='%{$GREEN_BOLD%}$(git_current_branch)$(git_prompt_short_sha)$(git_prompt_status)%{$RESET_COLOR%}'

bindkey -v

autoload -z edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

