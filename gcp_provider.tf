# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# Terraform + GCP Provider
#
# Single source of truth for terraform version pinning, provider version
# pinning, and provider runtime config. Soft-linked into every foundation/*
# directory as `gcp_provider.tf`. One file, one symlink per state directory.
# ---------------------------------------------------------------------------------------------------------------------
#
# Authentication model
# --------------------
# Every foundation Terraform run authenticates as smc-tf-foundation-sa
# (project smc-ops), but the SA email is never named inside any *.tf file.
# Identity is chosen at RUNTIME: chris@ (who holds
# roles/iam.serviceAccountTokenCreator on the SA) impersonates it via two
# env vars, one for the provider and one for the GCS backend:
#
#   export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=smc-tf-foundation-sa@smc-ops.iam.gserviceaccount.com
#   export GOOGLE_BACKEND_IMPERSONATE_SERVICE_ACCOUNT=$GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
#
# The SA is PLAN-ONLY at the Org. It can apply only during a change window
# that chris@ opens in foundation/iam/gcp-org/ (see foundation/readme.md,
# section 4). API calls made as the SA bill to smc-ops (its quota project),
# so the APIs Terraform uses must be enabled there.
#
# Why not `impersonate_service_account` in the backend or provider? Pinning
# the SA email in a *.tf file couples the runtime identity to the IaC source;
# leaving it to the environment lets the same code run as chris@, as the SA,
# or later from CI.
#
# No service-account keys: org policy iam.disableServiceAccountKeyCreation
# blocks creating them, and auth is always token-based.

terraform {
  required_version = "~> 1.10"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  region = "us-west1"
  zone   = "us-west1-a"

  # Imports must never stamp a "goog-terraform-provisioned" label onto live
  # resources; the IaC describes GCP as it is.
  add_terraform_attribution_label = false
}

provider "google-beta" {
  region = "us-west1"
  zone   = "us-west1-a"

  # Imports must never stamp a "goog-terraform-provisioned" label onto live
  # resources; the IaC describes GCP as it is.
  add_terraform_attribution_label = false
}
