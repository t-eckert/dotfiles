# Path to your oh-my-zsh installation.
export ZSH="/home/t_eck/.oh-my-zsh"

ZSH_THEME="juanghurtado"
DISABLE_UPDATE_PROMPT="true"
ENABLE_CORRECTION="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"

plugins=(git)

source $ZSH/oh-my-zsh.sh

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

LS_COLORS='no=0;97:fi=0;34:di=1;97:ln=1;97:pi=0;32:ex=1;35:ow=1;97'

alias vi=nvim
alias py=python3.9
alias md=mkdir
alias ls="ls --color -AF"

# Wire into node version manager
export NVM_DIR=~/.nvm
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
