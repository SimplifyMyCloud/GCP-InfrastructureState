#!/usr/bin/env bash
# ---------------------------------------------------------------------------------------------------------------------
# gamilas-redteam — provisioner 00 — base system + runtimes
# Brings the Ubuntu 22.04 base current and lays the foundation every later tier needs:
# build toolchain, Python (pip + pipx), a current Go (many modern web/cloud tools are Go),
# and the common net/CLI utilities. Idempotent-ish: safe to re-run.
# ---------------------------------------------------------------------------------------------------------------------
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# Wait out cloud-init's apt lock on first boot before we touch apt ourselves.
cloud-init status --wait 2>/dev/null || true

apt-get update -y
apt-get upgrade -y

apt-get install -y --no-install-recommends \
  ca-certificates curl wget git unzip zip tar gnupg lsb-release software-properties-common \
  build-essential pkg-config make gcc \
  python3 python3-pip python3-venv pipx \
  jq ripgrep net-tools dnsutils iputils-ping traceroute netcat-openbsd socat openssl \
  tmux vim less tree htop

# pipx puts CLI tools on PATH for every login shell without polluting system Python.
pipx ensurepath || true
PIPX_BIN_DIR=/usr/local/bin
export PIPX_HOME=/opt/pipx
export PIPX_BIN_DIR
mkdir -p "$PIPX_HOME"

# --- Go toolchain (pinned) ------------------------------------------------------------------------------------------
# Several recon/web tools (nuclei, httpx, ffuf, subfinder, amass, dalfox, gobuster) install
# cleanly via `go install`. Pin a known-good Go so builds are reproducible across bakes.
GO_VERSION="1.22.5"
ARCH="$(dpkg --print-architecture)"   # amd64 | arm64
curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" -o /tmp/go.tgz
rm -rf /usr/local/go
tar -C /usr/local -xzf /tmp/go.tgz
rm -f /tmp/go.tgz

# Make Go + Go-installed binaries available to all users and to the later provisioners.
install -d /opt/go
cat >/etc/profile.d/golang.sh <<'EOF'
export GOROOT=/usr/local/go
export GOPATH=/opt/go
export PATH=$PATH:/usr/local/go/bin:/opt/go/bin
EOF
chmod +x /etc/profile.d/golang.sh

echo "[00-base] base system + runtimes ready"
