bash -c 'set -euo pipefail
apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    wget openssh-server python3 python3-pip python3-venv git aria2 nano && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

mkdir -p /run/sshd ~/.ssh && chmod 700 ~/.ssh
echo "$PUBLIC_KEY" > ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
service ssh start

mkdir -p /workspace && cd /workspace
python3 -m venv .venv && source .venv/bin/activate
.venv/bin/pip install -U pip fastapi[standard] uvicorn[standard] gunicorn

# auto-cd and auto-activate for every bash login
grep -qxF "cd /workspace" ~/.bashrc || echo "cd /workspace" >> ~/.bashrc
grep -qxF "source /workspace/.venv/bin/activate" \
          ~/.bashrc || echo "source /workspace/.venv/bin/activate" >> ~/.bashrc

echo "✅  Container ready plain bash prompt, venv auto-activated."
tail -f /dev/null'
