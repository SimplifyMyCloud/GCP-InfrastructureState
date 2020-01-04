# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer - GCP Ops Project
# GCS Backend for Terraform State
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  backend "gcs" {
    bucket  = "iq9-terraform-states"
    prefix  = "terraform/state/foundation/gcp_projects/ops_env"
  }
}