bash -c '
set -euo pipefail

# --- 0 · OS + sshd only -------------------------------------------------
apt-get update -y && \
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    wget openssh-server python3 python3-pip python3-venv git aria2 nano && \
apt-get clean && rm -rf /var/lib/apt/lists/*

mkdir -p /run/sshd
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo "$PUBLIC_KEY" > ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
service ssh start     # <- keeps running in background

echo "--0. ✅  Base container ready – you can SSH now."


# --- 1 · shared workspace & venv ---------------------------------------
mkdir -p /workspace
cd /workspace
python3 -m venv .venv
source /workspace/.venv/bin/activate
/workspace/.venv/bin/pip install -U pip
/workspace/.venv/bin/pip install --no-cache-dir \
    fastapi[standard] uvicorn[standard] gunicorn
echo "--1. ✅  Venv installed"

#  --- 2 · auto-cd + auto-activate for future logins -------------------------
grep -qxF "cd /workspace"               ~/.bashrc || echo "cd /workspace" >> ~/.bashrc
grep -qxF "source /workspace/.venv/bin/activate" \
                                        ~/.bashrc || echo "source /workspace/.venv/bin/activate" >> ~/.bashrc
echo "--2. ✅  Added auto-cd and venv activation to ~/.bashrc"

# foreground process keeps pod alive



# --- 3 · Oh-My-Zsh layer ----------------------------------------------
apt-get install -y zsh             # already cached; safe to call every boot
export RUNZSH=no                   # installer: don’t auto-exec zsh

# 3a · bootstrap Oh-My-Zsh (first pod only)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash
  echo "--3a. ✅  Oh-My-Zsh installed"
fi

# 3b · write shared zshrc on the persistent volume (once)
if [ ! -f /workspace/.zshrc ]; then
  cat > /workspace/.zshrc <<'EOF'
# -------- /workspace/.zshrc (shared across pods) --------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"       # <-- simple built-in theme; add P10k later
plugins=(git)

source $ZSH/oh-my-zsh.sh

# always start here & activate venv
cd /workspace
source /workspace/.venv/bin/activate
EOF
  echo "--3b. ✅  /workspace/.zshrc created"
fi

# 3c · link roots rc file to the shared one (idempotent)
ln -sf /workspace/.zshrc /root/.zshrc

# 3d · make zsh the login shell *and* jump into it from bash
chsh -s "$(command -v zsh)" root || usermod -s "$(command -v zsh)" root
grep -qxF "exec zsh -l" /root/.bashrc || \
  echo 'command -v zsh >/dev/null && exec zsh -l' >> /root/.bashrc

echo "--3. ✅  Oh-My-Zsh ready; logins will use z-shell"


tail -f /dev/null  
'
