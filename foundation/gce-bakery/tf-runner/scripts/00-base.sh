#!/usr/bin/env bash
# ---------------------------------------------------------------------------------------------------------------------
# tf-runner — provisioner 00 — base system
# Brings Ubuntu 22.04 current and installs the small set of utilities the runner needs:
# git (to pull the IaC repo), jq (to parse plan/state JSON), and the usual fetch/unzip
# tooling for installing terraform. Deliberately lean — a runner should be boring.
# ---------------------------------------------------------------------------------------------------------------------
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

cloud-init status --wait 2>/dev/null || true

apt-get update -y
apt-get upgrade -y

apt-get install -y --no-install-recommends \
  ca-certificates curl wget gnupg lsb-release unzip \
  git jq make openssh-client

echo "[00-base] base system ready"
