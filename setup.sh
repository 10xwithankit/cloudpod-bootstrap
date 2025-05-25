#!/bin/bash
set -e  # Exit on error

apt update
apt install -y zsh git curl python3.12-venv aria2 nano

chsh -s $(which zsh)

if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "✅ Oh My Zsh already installed at $HOME/.oh-my-zsh"
else
  echo "🎨 Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
  echo "🌈 Installing Powerlevel10k theme..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
else
  echo "✅ Powerlevel10k already exists. Skipping..."
fi

wget -O ~/.p10k.zsh https://raw.githubusercontent.com/romkatv/powerlevel10k/master/config/p10k-lean.zsh

echo "🔌 Installing plugins..."
echo "🔌 Installing plugins..."

if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
  echo "➕ Installing zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
else
  echo "✅ zsh-autosuggestions already exists. Skipping..."
fi

if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
  echo "➕ Installing zsh-syntax-highlighting..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting
else
  echo "✅ zsh-syntax-highlighting already exists. Skipping..."
fi

echo "⚙️ Writing .zshrc..."
cat > ~/.zshrc <<EOF
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source \$ZSH/oh-my-zsh.sh
EOF

echo "⚙️ Writing Powerlevel10k config..."
cat > ~/.zshrc <<EOF
export ZSH="$HOME/.oh-my-zsh"
export POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source \$ZSH/oh-my-zsh.sh
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
EOF


VENV_DIR="/workspace/venv"

if [ -d "$VENV_DIR" ]; then
  echo "✅ Virtual environment already exists. Activating..."
else
  echo "📦 Creating virtual environment at $VENV_DIR..."
  python3 -m venv "$VENV_DIR"
fi

# Activate the environment
source "$VENV_DIR/bin/activate"

# Optional: Upgrade pip (safe)
pip install --upgrade pip

exec zsh
