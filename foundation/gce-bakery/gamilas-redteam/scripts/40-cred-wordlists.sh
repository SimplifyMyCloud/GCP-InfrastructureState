#!/usr/bin/env bash
# ---------------------------------------------------------------------------------------------------------------------
# gamilas-redteam — provisioner 40 — credential attacks & wordlists
# Online auth attacks (hydra/medusa), offline hash cracking (john/hashcat), and the
# wordlists everything above consumes (SecLists + rockyou). Against yamato, online
# brute-force at /wiki dies at IAP (Google login, MFA, no app password to guess), and
# Cloud Armor rate-limits the noise — but the kit must be complete for the demo.
# ---------------------------------------------------------------------------------------------------------------------
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

# hydra/medusa/john/hashcat live in Ubuntu's universe repo. NOTE: `seclists` and
# `wordlists` are Kali-only packages — they do NOT exist on Ubuntu — so we fetch SecLists
# from source instead (it bundles rockyou too). Keep these on their own apt line so a
# wordlist hiccup can never block the cracking tools.
apt-get install -y --no-install-recommends \
  hydra medusa john hashcat

# --- SecLists (from GitHub; provides the wordlists every web/cred tool consumes) --------------------------------------
# Shallow clone keeps it lean-ish. Lands at /usr/share/seclists — the path the profiles use.
if [ ! -d /usr/share/seclists ]; then
  git clone --depth 1 https://github.com/danielmiessler/SecLists.git /usr/share/seclists
fi

# Provide the conventional /usr/share/wordlists layout tools assume.
mkdir -p /usr/share/wordlists
ln -sf /usr/share/seclists /usr/share/wordlists/seclists

# rockyou ships inside SecLists, tarred — unpack it to the conventional spot.
ROCKYOU_TGZ="$(find /usr/share/seclists -name 'rockyou.txt.tar.gz' | head -n1)"
if [ -n "$ROCKYOU_TGZ" ] && [ ! -f /usr/share/wordlists/rockyou.txt ]; then
  tar -xzf "$ROCKYOU_TGZ" -C /usr/share/wordlists/
fi

# Make the dirb wordlists reachable at the conventional /usr/share/wordlists/dirb path
# (Ubuntu's dirb package installs them under /usr/share/dirb/wordlists).
if [ -d /usr/share/dirb/wordlists ] && [ ! -e /usr/share/wordlists/dirb ]; then
  ln -sf /usr/share/dirb/wordlists /usr/share/wordlists/dirb
fi

echo "[40-cred] credential attacks & wordlists ready"
