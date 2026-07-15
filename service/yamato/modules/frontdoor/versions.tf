# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — module: frontdoor
# Provider version constraints (no provider config — that lives in the root)
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = "~> 1.10"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    # google-beta is required for google_project_service_identity, which forces
    # creation of the IAP service agent so terraform can bind it to run.invoker.
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.0"
    }
  }
}
