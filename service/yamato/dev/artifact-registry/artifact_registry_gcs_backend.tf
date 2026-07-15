# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — yamato / dev / artifact-registry — Terraform State (GCS backend)
# ---------------------------------------------------------------------------------------------------------------------
#
# State for this directory's resources lives in:
#   gs://iq9-iac-ops-tf-state-bucket/terraform/state/service/yamato/dev/artifact-registry/
#
# Authentication is intentionally absent from this block — identity is resolved
# by Application Default Credentials at runtime. See ../../../gcp_provider.tf and
# the repo-root gcp_provider.tf for the full auth model.

terraform {
  backend "gcs" {
    bucket = "iq9-iac-ops-tf-state-bucket"
    prefix = "terraform/state/service/yamato/dev/artifact-registry"
  }
}
