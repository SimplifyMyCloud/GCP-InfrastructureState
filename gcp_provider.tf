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
# Every foundation Terraform run authenticates as the long-lived
# iq9-tf-foundation-sa service account, but the SA email is never named
# inside any *.tf file. Identity is resolved at runtime by Application
# Default Credentials (ADC) — neither the provider blocks below nor any
# backend file pins a service account by string. Two paths reach the SA:
#
#   1. Runner VM (`iq9-tf-runner` in `iq9-ops-iac`) — the foundation SA is
#      attached to the VM as its identity. The Google SDK auto-detects the
#      GCE metadata server (169.254.169.254) and fetches a token for the
#      attached SA. Both the provider and the GCS backend pick it up. No
#      env vars, no flags, no per-state config.
#
#   2. Developer laptop — one gcloud command writes the impersonation
#      directly into ADC:
#
#        gcloud auth application-default login \
#          --impersonate-service-account=iq9-tf-foundation-sa@iq9-ops-iac.iam.gserviceaccount.com
#
#      gcloud stores the impersonation chain in
#      ~/.config/gcloud/application_default_credentials.json, the SDK reads
#      it transparently, and the same ADC source is used by the provider
#      AND the GCS backend. The developer must hold
#      roles/iam.serviceAccountTokenCreator on the foundation SA (granted
#      only to the foundation reviewers group).
#
# Why not `impersonate_service_account` in the backend or provider? Pinning
# the SA email by string in a *.tf file would (a) burn the identity into
# git history forever, (b) couple the runtime identity to the IaC source
# rather than to the runner environment, and (c) break VM runs because the
# SA would have to impersonate itself, which requires tokenCreator on
# itself. Letting ADC handle it keeps the IaC unaware of which identity is
# making the call — the runner determines who you are.
#
# No service-account keys exist anywhere. Org policy
# iam.disableServiceAccountKeyCreation blocks creation; auth is always
# token-based.

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
}

provider "google-beta" {
  region = "us-west1"
  zone   = "us-west1-a"
}
