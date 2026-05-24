#!/usr/bin/env bash
# ---------------------------------------------------------------------------------------------------------------------
# gamilas-redteam — provisioner 30 — GCP attack & cloud-IAM suite
# This is the tier that makes the demo a GCP demo. After a "stolen credential" lands
# (an SA key, or a token lifted from the metadata server via SSRF), the attacker pivots
# into the cloud control plane and tries to escalate / take over service accounts.
# The point of Profile 2: the runtime SA is least-privilege (cloudsql.client + one secret
# accessor, nothing else), org policies block the easy escalations, and every gcloud /
# API call lands in the org-wide audit log sink. The blast radius is a pinhole.
# ---------------------------------------------------------------------------------------------------------------------
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

export PIPX_HOME=/opt/pipx
export PIPX_BIN_DIR=/usr/local/bin

# --- Google Cloud SDK (official apt repo) ---------------------------------------------------------------------------
install -d -m 0755 /usr/share/keyrings
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
  > /etc/apt/sources.list.d/google-cloud-sdk.list
apt-get update -y
apt-get install -y --no-install-recommends google-cloud-cli

# Postgres client — Profile 2 tries to reach Cloud SQL directly. It can't: the instance
# is private-IP only, reachable solely via Direct VPC egress from the Cloud Run SA. The
# attempt timing out is the demo beat. (psql also drives sqlmap's --os-shell attempts.)
apt-get install -y --no-install-recommends postgresql-client

# --- Multi-cloud auditors (pipx-isolated) ---------------------------------------------------------------------------
# ScoutSuite + Prowler both enumerate GCP IAM/config and produce a report — exactly what
# an attacker (and a defender) runs post-compromise to find escalation paths.
pipx install scoutsuite || pipx install --include-deps scoutsuite || true
pipx install prowler || true

# --- GCP-specific offensive tooling ---------------------------------------------------------------------------------
install -d /opt/gcp-attack

# Google's own gcp_scanner — enumerates what a set of credentials can actually touch.
git clone --depth 1 https://github.com/google/gcp_scanner.git /opt/gcp-attack/gcp_scanner || true
pipx install /opt/gcp-attack/gcp_scanner || true

# Rhino Security Labs GCP IAM privilege-escalation scripts — the canonical SA-takeover
# test set (e.g. actAs / setIamPolicy / deploy-function pivots). Used read-only in the
# demo to PROVE the paths are closed.
git clone --depth 1 https://github.com/RhinoSecurityLabs/GCP-IAM-Privilege-Escalation.git \
  /opt/gcp-attack/gcp-iam-privesc || true

# GCPBucketBrute — guesses GCS bucket names + checks for misconfigured public/listable
# buckets. Our log-warehouse + app buckets are locked, so this is another clean miss.
git clone --depth 1 https://github.com/RhinoSecurityLabs/GCPBucketBrute.git \
  /opt/gcp-attack/gcpbucketbrute || true
if [ -f /opt/gcp-attack/gcpbucketbrute/requirements.txt ]; then
  python3 -m venv /opt/gcp-attack/gcpbucketbrute/.venv
  /opt/gcp-attack/gcpbucketbrute/.venv/bin/pip install -r /opt/gcp-attack/gcpbucketbrute/requirements.txt || true
fi

echo "[30-cloud] GCP attack & cloud-IAM suite ready"
