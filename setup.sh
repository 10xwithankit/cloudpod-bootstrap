#!/bin/bash
set -euxo pipefail

echo "🛠 Running clean setup.sh..."

# === SSH Setup ===
mkdir -p /root/.ssh
chmod 700 /root/.ssh
if [[ -n "${PUBLIC_KEY:-}" ]]; then
  echo "$PUBLIC_KEY" > /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  echo "✅ SSH key injected"
else
  echo "⚠️ No PUBLIC_KEY found"
fi

mkdir -p /run/sshd
ssh-keygen -A
service ssh restart || /etc/init.d/ssh restart

# === ZSH Setup ===
export RUNZSH=no
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k" || true
git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" || true
git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" || true

if [ ! -f ~/.zshrc ]; then
  cat <<EOF > ~/.zshrc
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source \$ZSH/oh-my-zsh.sh
EOF
fi

# === Python Virtualenv ===
cd /workspace
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install huggingface_hub torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

echo "✅ setup.sh done"
echo 'cd /workspace' >> ~/.bashrc
echo 'source /workspace/.venv/bin/activate || true' >> ~/.bashrc
echo 'command -v zsh && exec zsh || true' >> ~/.bashrc