# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCS Backend for Terraform State
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  backend "gcs" {
    bucket  = "iq9-tf-states"
    prefix  = "terraform/state/foundation/gcp_folders"
  }
}