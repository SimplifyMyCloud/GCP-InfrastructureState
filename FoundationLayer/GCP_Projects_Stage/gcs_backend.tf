# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer - GCP Production Project
# GCS Backend for Terraform State
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  backend "gcs" {
    bucket  = "iq9-terraform-shared-state-bucket"
    prefix  = "terraform/state/foundation/gcp_projects/stage_env"
  }
}