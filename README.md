# cloudpod-bootstrap

A cloud-agnostic setup script for preparing clean Ubuntu-based pods to run AI workloads (FastAPI servers, workers, and more).  
Works across RunPod, AWS, Paperspace, and local Linux.

---

## ✅ What This Does

- Installs core packages (Python, pip, zsh, aria2, git, cloudflared)
- Sets up ZSH with Powerlevel10k and plugins
- Prepares Hugging Face config + login via `HF_TOKEN`
- Creates symlinks and folder structure
- Leaves `run.sh` blank so your app repo controls what to launch

---

## 🚀 How to Use

1. Clone this repo:
```bash
git clone https://github.com/10xwithankit/cloudpod-bootstrap.git /workspace
cd /workspace
bash setup.sh
git clone https://github.com/YOUR-ORG/YOUR-APP-REPO.git /workspace/app
cd /workspace/app
bash run.sh
```

##  ⚙️ Environment Variables (optional)

| Variable      | Description                                        |
| ------------- | -------------------------------------------------- |
| `HF_TOKEN`    | (Optional) Hugging Face token for model access     |
| `HF_HOME`     | Hugging Face cache directory (default: `.hf/home`) |
| `TUNNEL_NAME` | Cloudflare tunnel name                             |
| `API_PORT`    | Port for serving FastAPI (default: `7860`)         |


MIT licensed • Built by @10xwithankit