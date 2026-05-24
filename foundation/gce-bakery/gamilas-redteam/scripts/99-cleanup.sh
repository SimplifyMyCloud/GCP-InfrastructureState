#!/usr/bin/env bash
# ---------------------------------------------------------------------------------------------------------------------
# gamilas-redteam — provisioner 99 — cleanup / de-bloat
# Runs LAST. Strips apt caches, logs, machine identity, and any provisioning crumbs so the
# published image/snapshot is clean, smaller, and carries nothing sensitive. The booted
# demo VM regenerates its own host keys and machine-id on first boot.
# ---------------------------------------------------------------------------------------------------------------------
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get -y autoremove --purge
apt-get -y clean
rm -rf /var/lib/apt/lists/*

# Truncate logs.
find /var/log -type f -exec truncate -s 0 {} + 2>/dev/null || true

# Reset machine identity so cloned VMs aren't all the same host.
truncate -s 0 /etc/machine-id || true
rm -f /var/lib/dbus/machine-id || true
ln -s /etc/machine-id /var/lib/dbus/machine-id 2>/dev/null || true

# Drop any SSH host keys (regenerated on first boot) and shell history.
rm -f /etc/ssh/ssh_host_* || true
rm -f /root/.bash_history || true
unset HISTFILE || true

echo "[99-cleanup] image cleaned — ready to publish"
