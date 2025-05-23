bash -c '
set -euo pipefail

# 0 · OS packages 
apt-get update -y && \
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  wget curl ca-certificates openssh-server python3 python3-pip python3-venv git aria2 nano && \
apt-get clean && rm -rf /var/lib/apt/lists/*

# 1 · SSH 
mkdir -p /run/sshd  ~/.ssh && chmod 700 ~/.ssh
echo "$PUBLIC_KEY" > ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
service ssh start

# 2 · Workspace + venv 
mkdir -p /workspace && cd /workspace
python3 -m venv .venv
source .venv/bin/activate
pip install -U pip fastapi[standard] uvicorn[standard] gunicorn

# 3 · cloudflared from official repo 
if ! command -v cloudflared >/dev/null; then
  echo "⬇️  Installing cloudflared…"
  mkdir -p /usr/share/keyrings
  curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg \
       | tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] \
        https://pkg.cloudflare.com/cloudflared any main" \
        > /etc/apt/sources.list.d/cloudflared.list
  apt-get update -y
  apt-get install -y cloudflared
fi
echo "--3 ✅ cloudflared $(cloudflared --version | cut -d\" \" -f3) installed"

# 4 · launch tunnel 
if [ -z "${CF_TUNNEL_TOKEN:-}" ]; then
  echo "❌ CF_TUNNEL_TOKEN not set,  tunnel NOT started"
else
  echo "🌐 Starting tunnel → http://localhost:8000 ..."
  cloudflared tunnel run \
      --token "$CF_TUNNEL_TOKEN" \
      --url http://localhost:8000 \
      &> /workspace/cloudflared.log &
fi

# 5 · convenience for future SSH sessions ----------------------------------
grep -qxF "cd /workspace" ~/.bashrc                || echo "cd /workspace" >> ~/.bashrc
grep -qxF "source /workspace/.venv/bin/activate"   || \
      echo "source /workspace/.venv/bin/activate" >> ~/.bashrc

echo "✅  Pod ready, FastAPI on :8000, tunnel up if token present."
tail -f /dev/null
'
