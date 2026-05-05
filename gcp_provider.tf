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
# iq9-tf-foundation-sa service account. Two paths get there:
#
#   1. Runner VM (`iq9-tf-runner` in `iq9-ops-iac`) — the foundation SA is
#      attached to the VM as its identity. Application Default Credentials
#      surface the SA automatically; no extra config needed.
#
#   2. Developer laptop — `gcloud auth application-default login` as the
#      developer's human identity, then export the impersonation env var:
#
#        export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=iq9-tf-foundation-sa@iq9-ops-iac.iam.gserviceaccount.com
#
#      The provider plugin auto-picks it up and impersonates the SA. The
#      developer must hold roles/iam.serviceAccountTokenCreator on the
#      foundation SA (granted only to the foundation reviewers group).
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
