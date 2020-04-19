# ---------------------------------------------------------------------------------------------------------------------
# Service Layer - GCP Dev Project
# GCS Backend for Terraform State
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  backend "gcs" {
    bucket = "iq9-terraform-shared-state-bucket"
    prefix = "terraform/state/service/dev-env/smc-hello-app/helloworld"
  }
}