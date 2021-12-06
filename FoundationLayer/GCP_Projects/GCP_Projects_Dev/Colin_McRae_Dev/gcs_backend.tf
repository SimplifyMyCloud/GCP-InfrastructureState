# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer - GCP Dev Project
# GCS Backend for Terraform State
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  backend "gcs" {
    bucket = "iq9-terraform-shared-state-bucket"
    prefix = "terraform/state/foundation/gcp_projects/dev_env/colin_mcrae_dev"
  }
}