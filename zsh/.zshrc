# Path to your oh-my-zsh installation.
export ZSH="/home/t_eck/.oh-my-zsh"

ZSH_THEME="juanghurtado"
DISABLE_UPDATE_PROMPT="true"
ENABLE_CORRECTION="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"

plugins=(
  docker
  git
  golang
  node
  python
  zsh-autocomplete
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

LS_COLORS='no=0;97:fi=0;34:di=1;97:ln=1;97:pi=0;32:ex=1;35:ow=1;97'

alias vi=nvim
alias v=nvim
alias py=python3.9
alias md=mkdir
alias mcd="mkdir $_ && cd $_"
alias ls="ls --color -AF"
alias gs="git status"
alias venv="source .venv/bin/activate"
alias cat="bat"
alias grab="clip.exe < "
alias format_json="py -m json.tool"
alias fixtime="sudo hwclock -s"

# Wire into node version manager
export NVM_DIR=~/.nvm
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
