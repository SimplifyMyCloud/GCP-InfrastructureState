# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — module: cloudsql
# Provider version constraints (no provider config — that lives in the root)
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = "~> 1.10"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
