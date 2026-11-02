#!/usr/bin/env bash
# ---------------------------------------------------------------------------------------------------------------------
# tf-runner — provisioner 99 — cleanup / de-bloat
# Runs LAST. Strips apt caches, logs, machine identity, and host keys so the published
# image is clean and carries no per-build state. The booted runner regenerates its own
# host keys + machine-id on first boot.
# ---------------------------------------------------------------------------------------------------------------------
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get -y autoremove --purge
apt-get -y clean
rm -rf /var/lib/apt/lists/*

find /var/log -type f -exec truncate -s 0 {} + 2>/dev/null || true

truncate -s 0 /etc/machine-id || true
rm -f /var/lib/dbus/machine-id || true
ln -s /etc/machine-id /var/lib/dbus/machine-id 2>/dev/null || true

rm -f /etc/ssh/ssh_host_* || true
rm -f /root/.bash_history || true
unset HISTFILE || true

echo "[99-cleanup] image cleaned — ready to publish"
