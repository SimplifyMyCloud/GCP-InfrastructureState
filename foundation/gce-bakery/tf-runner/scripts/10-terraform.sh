#!/usr/bin/env bash
# ---------------------------------------------------------------------------------------------------------------------
# tf-runner — provisioner 10 — Terraform + linters
# Installs a PINNED Terraform (TERRAFORM_VERSION, passed from the recipe) so every bake
# produces a runner that agrees with the repo's required_version. Also tflint + terraform-docs
# for plan-time validation and doc generation in the pipeline.
# ---------------------------------------------------------------------------------------------------------------------
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

: "${TERRAFORM_VERSION:?TERRAFORM_VERSION must be set by the Packer recipe}"
ARCH="$(dpkg --print-architecture)"   # amd64 | arm64

# --- Terraform (pinned, from the official HashiCorp release zip) ----------------------------------------------------
curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" \
  -o /tmp/terraform.zip
unzip -o /tmp/terraform.zip -d /usr/local/bin
rm -f /tmp/terraform.zip
terraform version

# --- tflint ---------------------------------------------------------------------------------------------------------
curl -fsSL https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash || true

# --- terraform-docs -------------------------------------------------------------------------------------------------
TFDOCS_VER="0.19.0"
curl -fsSL "https://github.com/terraform-docs/terraform-docs/releases/download/v${TFDOCS_VER}/terraform-docs-v${TFDOCS_VER}-linux-${ARCH}.tar.gz" \
  -o /tmp/tfdocs.tgz
tar -C /usr/local/bin -xzf /tmp/tfdocs.tgz terraform-docs && chmod +x /usr/local/bin/terraform-docs
rm -f /tmp/tfdocs.tgz

echo "[10-terraform] terraform ${TERRAFORM_VERSION} + tflint + terraform-docs ready"
