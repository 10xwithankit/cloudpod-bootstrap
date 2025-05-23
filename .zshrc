export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

if [[ "$VIRTUAL_ENV" == "" ]]; then
  echo "⚠️ Warning: You are NOT in the bootstrap virtualenv (/workspace/.venv)"
  echo "👉 Run: source /workspace/.venv/bin/activate"
fi

# Custom aliases
alias ws="cd /workspace"
