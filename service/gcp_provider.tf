# ---------------------------------------------------------------------------------------------------------------------
# Service Layer
# Terraform + GCP Provider
#
# Single source of truth for terraform/provider version pinning and provider
# runtime config for the Service Layer. Soft-linked into every Service Layer
# environment-root directory (service/<app>/<env>/<service>/) as
# `gcp_provider.tf`. One file, one symlink per state-root directory.
#
# Note: this file lives in the Service Layer and is intentionally separate from
# the Foundation Layer's repo-root gcp_provider.tf. The two layers run under
# different identities and different review bars (Foundation = hardcoded, higher
# approval count; Service = variables + modules, lighter approval count). Keeping
# the provider files separate keeps each layer self-describing.
# ---------------------------------------------------------------------------------------------------------------------
#
# Authentication model
# --------------------
# Same principle as the Foundation Layer: identity is resolved at runtime by
# Application Default Credentials (ADC). No service-account email is pinned in
# any *.tf file, no `credentials` field, no `impersonate_service_account` block,
# and no service-account keys exist anywhere (org policy
# iam.disableServiceAccountKeyCreation blocks key creation).
#
#   - Runner VM: ADC = the metadata-server token for the SA attached to the
#     runner. The Google SDK auto-detects it; both the provider and the GCS
#     backend pick it up with no extra config.
#
#   - Developer laptop: `gcloud auth application-default login
#     --impersonate-service-account=<service-layer SA>` writes the impersonation
#     chain into ADC, and the SDK reads it transparently.
#
# The specific identity the Service Layer runs as is determined by the runner /
# impersonation configuration, NOT by anything in this repo. See the repo-root
# gcp_provider.tf for the full rationale behind keeping identity out of the IaC.
#
# Region note: this provider only sets region/zone (us-west1, Oregon, to match
# the Foundation Layer). It deliberately does NOT set a default `project`,
# because each environment targets a different project. Every resource and
# module sets `project` explicitly from a variable instead.

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
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
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
