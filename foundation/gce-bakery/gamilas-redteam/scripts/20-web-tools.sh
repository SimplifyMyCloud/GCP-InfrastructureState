#!/usr/bin/env bash
# ---------------------------------------------------------------------------------------------------------------------
# gamilas-redteam — provisioner 20 — web application attack suite
# The core of a webapp red-team engagement: content discovery, vuln scanning, injection,
# XSS, and a DAST proxy. Against yamato, the public "/" is a static page (nothing to
# find), and "/wiki" sits behind IAP — so unauth scans get a 302 to Google login, never
# the app. With stolen creds (Profile 2) these run against the real app and meet the
# next walls (private Cloud SQL, least-priv SA). Everything is logged at the LB + app.
# ---------------------------------------------------------------------------------------------------------------------
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# shellcheck disable=SC1091
source /etc/profile.d/golang.sh
export GOBIN=/opt/go/bin

# --- apt-sourced web tooling ----------------------------------------------------------------------------------------
apt-get install -y --no-install-recommends \
  nikto sqlmap wfuzz dirb gobuster \
  ruby ruby-dev   # wpscan gem needs ruby headers

# wpscan — even though yamato is not WordPress, it ships in any red-team kit; harmless.
gem install --no-document wpscan || true

# --- Go-based content discovery & injection -------------------------------------------------------------------------
go install github.com/ffuf/ffuf/v2@latest
go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install github.com/hahwul/dalfox/v2@latest   # XSS scanner

# Pull the nuclei template corpus now so the baked image scans offline-ready.
/opt/go/bin/nuclei -update-templates -update-template-dir /opt/nuclei-templates || true

# --- feroxbuster (fast recursive content discovery) -----------------------------------------------------------------
FEROX_ARCH="$(dpkg --print-architecture)"
if [ "$FEROX_ARCH" = "amd64" ]; then
  curl -fsSL https://github.com/epi052/feroxbuster/releases/latest/download/x86_64-linux-feroxbuster.tar.gz -o /tmp/ferox.tgz
  tar -C /usr/local/bin -xzf /tmp/ferox.tgz feroxbuster && rm -f /tmp/ferox.tgz
fi

# --- OWASP ZAP (DAST) -----------------------------------------------------------------------------------------------
# Headless baseline/full scans drive Profile 1 and Profile 2's app phase. Pin a known-good
# version, but if that ever 404s (ZAP bumps versions and retires old tags), fall back to
# resolving the latest release asset — and never let one optional tool kill the whole bake.
ZAP_VER="2.17.0"
ZAP_URL="https://github.com/zaproxy/zaproxy/releases/download/v${ZAP_VER}/ZAP_${ZAP_VER}_Linux.tar.gz"
if ! curl -fsSL "$ZAP_URL" -o /tmp/zap.tgz; then
  echo "[20-web] pinned ZAP ${ZAP_VER} unavailable; resolving latest release asset"
  ZAP_URL="$(curl -fsSL https://api.github.com/repos/zaproxy/zaproxy/releases/latest | grep -o 'https://[^"]*ZAP_[0-9.]*_Linux\.tar\.gz' | head -n1 || true)"
  { [ -n "$ZAP_URL" ] && curl -fsSL "$ZAP_URL" -o /tmp/zap.tgz; } || echo "[20-web] WARNING: ZAP unavailable — skipping (install later by hand)"
fi
if [ -s /tmp/zap.tgz ]; then
  mkdir -p /opt/zap
  tar -C /opt/zap --strip-components=1 -xzf /tmp/zap.tgz
  rm -f /tmp/zap.tgz
  ln -sf /opt/zap/zap.sh /usr/local/bin/zap.sh
  echo "[20-web] OWASP ZAP ready"
fi

echo "[20-web] web application attack suite ready"
