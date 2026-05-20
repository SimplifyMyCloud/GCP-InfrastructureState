# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — yamato / dev / cloudrun — Terraform State (GCS backend)
# ---------------------------------------------------------------------------------------------------------------------
#
# State for this directory's resources lives in:
#   gs://iq9-iac-ops-tf-state-bucket/terraform/state/service/yamato/dev/cloudrun/
#
# Identity is resolved by ADC at runtime; nothing is pinned here. See
# ../../../gcp_provider.tf for the auth model.

terraform {
  backend "gcs" {
    bucket = "iq9-iac-ops-tf-state-bucket"
    prefix = "terraform/state/service/yamato/dev/cloudrun"
  }
}
