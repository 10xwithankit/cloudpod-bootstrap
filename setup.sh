#!/bin/bash

set -e  # Exit on any error

# Navigate to workspace
cd /workspace || true

echo "🚀 Starting cloudpod-bootstrap setup..."

# === Essentials ===
echo "📦 Installing system packages..."
# Check if packages are already installed
for pkg in curl git nano zsh python3 python3-pip python3-venv unzip wget aria2; do
  if ! dpkg -l | grep -q "$pkg"; then
    echo "Installing $pkg..."
    apt install -y "$pkg"
  else
    echo "$pkg is already installed."
  fi
done

# === Cloudflared CLI ===
echo "☁️ Installing Cloudflare tunnel CLI..."
if ! command -v cloudflared &> /dev/null; then
  echo "Downloading cloudflared..."
  wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
  chmod +x cloudflared-linux-amd64
  mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
else
  echo "cloudflared is already installed."
fi

# === ZSH and Oh My Zsh ===
echo "🎨 Setting up ZSH environment..."
# Check if ZSH is installed
if ! command -v zsh &> /dev/null; then
  echo "ZSH not found, installing..."
  apt install -y zsh
fi

# Only install Oh My Zsh if it’s not installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install Powerlevel10k theme and plugins if not already installed
if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
  echo "Installing Powerlevel10k theme..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
fi

if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
  echo "Installing zsh-autosuggestions plugin..."
  git clone https://github.com/zsh-users/zsh-autosuggestions \
    ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
  echo "Installing zsh-syntax-highlighting plugin..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

# Configure ZSH
if [ ! -f ~/.zshrc ]; then
  echo "🔁 Copying default .zshrc..."
  cp /workspace/.zshrc ~/.zshrc
fi

# Set default shell to ZSH
chsh -s $(which zsh) 2>/dev/null || true

# === Hugging Face token + cache ===
export HF_HOME=${HF_HOME:-/workspace/.hf/home}
mkdir -p /workspace/.hf
mkdir -p "$HF_HOME"

cd /workspace || true

echo "🐍 Creating and activating virtualenv..."
python3 -m venv /workspace/.venv
source /workspace/.venv/bin/activate

echo "✅ Virtualenv created at /workspace/.venv"
echo "💡 To use it: source /workspace/.venv/bin/activate"

echo "📦 Installing huggingface_hub CLI..."
pip install --upgrade pip
pip install huggingface_hub

echo "🧠 Installing PyTorch with CUDA 12.1 support..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Check if Hugging Face token exists in env or file
if [[ -n "$HF_TOKEN" && "$HF_TOKEN" != *"PLEASE_CHANGE_THIS"* ]]; then
  echo "🔐 Logging in with HF_TOKEN from env..."
  huggingface-cli login --token "$HF_TOKEN" --add-to-git-credential
elif [[ -f /workspace/.hf/token.txt ]]; then
  echo "🔐 Logging in with token from .hf/token.txt..."
  huggingface-cli login --token $(cat /workspace/.hf/token.txt) --add-to-git-credential
else
  echo "⚠️ No Hugging Face token provided. Model downloads may fail."
fi

# === Cloudflare tunnel config ===
mkdir -p /workspace/.cloudflared
ln -sf /workspace/.cloudflared ~/.cloudflared

# === Powerlevel10k config ===
if [[ ! -f ~/.p10k.zsh ]]; then
  echo "💎 Creating default Powerlevel10k config"
  curl -s https://raw.githubusercontent.com/romkatv/powerlevel10k-media/master/config/p10k-classic.zsh -o ~/.p10k.zsh
fi

# === Complete ===
echo "✅ Setup complete!"
echo "💡 You can now run: bash run.sh or exec zsh"

# Optional auto-start
if [[ "$START_ZSH" == "true" ]]; then
  echo "✨ Launching ZSH shell..."
  source /workspace/.venv/bin/activate || true
  exec zsh
fi
