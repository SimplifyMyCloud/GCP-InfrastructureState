#!/usr/bin/env bash
# ---------------------------------------------------------------------------------------------------------------------
# gamilas-redteam — provisioner 10 — recon & enumeration
# The first thing a red team does against a target: map the perimeter. Port/service
# discovery, TLS posture, DNS, subdomains, live-host probing, tech fingerprinting.
# Against yamato these all bounce off the HTTPS LB / Cloud Armor — and every probe is
# logged. That "wall of nothing" is the point of Profile 1.
# ---------------------------------------------------------------------------------------------------------------------
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# shellcheck disable=SC1091
source /etc/profile.d/golang.sh

# --- apt-sourced classics -------------------------------------------------------------------------------------------
apt-get install -y --no-install-recommends \
  nmap masscan dnsrecon whatweb

# testssl.sh — thorough TLS/cipher/cert audit, no compile needed.
git clone --depth 1 https://github.com/drwetter/testssl.sh.git /opt/testssl.sh
ln -sf /opt/testssl.sh/testssl.sh /usr/local/bin/testssl.sh

# --- Go-based ProjectDiscovery + friends ----------------------------------------------------------------------------
# Modern, fast, well-maintained. Installed to /opt/go/bin (on PATH via golang.sh).
export GOBIN=/opt/go/bin
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest
go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
go install github.com/owasp-amass/amass/v4/...@master

echo "[10-recon] recon & enumeration ready"
