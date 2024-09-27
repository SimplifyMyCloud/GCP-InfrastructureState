# Foundation Layer - GCP Provider
terraform {
  required_version = ">=0.15"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.49.0, < 5.0"
    }

    google-beta = {
      source =  "hashicorp/google-beta"
      version = "~> 4.0"
    }
  }
}