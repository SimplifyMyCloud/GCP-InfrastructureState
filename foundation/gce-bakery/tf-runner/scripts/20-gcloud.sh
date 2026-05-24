#!/usr/bin/env bash
# ---------------------------------------------------------------------------------------------------------------------
# tf-runner — provisioner 20 — Google Cloud SDK
# The runner authenticates by ADC off the attached SA (metadata server) and, for the
# RO/RW swap, mints short-lived impersonated tokens with `gcloud auth print-access-token
# --impersonate-service-account`. Both need the gcloud CLI. gsutil (bundled) also gives a
# hand for poking at the GCS state bucket during incident response.
# ---------------------------------------------------------------------------------------------------------------------
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

install -d -m 0755 /usr/share/keyrings
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
  > /etc/apt/sources.list.d/google-cloud-sdk.list
apt-get update -y
apt-get install -y --no-install-recommends google-cloud-cli

echo "[20-gcloud] google-cloud-cli ready"
