# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Folders — Terraform State (GCS backend)
# ---------------------------------------------------------------------------------------------------------------------
#
# State for this directory's resources lives in:
#   gs://iq9-iac-ops-tf-state-bucket/terraform/state/foundation/gcp-folders/
#
# The bucket is in iq9-ops-iac, has uniform bucket-level access on, public
# access prevention enforced, and versioning enabled. Object access is
# restricted to iq9-tf-foundation-sa via roles/storage.objectAdmin granted
# at bucket scope.
#
# Authentication is intentionally absent from this block — there is no
# `impersonate_service_account` and no `credentials` field. Identity is
# resolved by Application Default Credentials at runtime: on the runner VM
# ADC = the metadata server token for the attached foundation SA, on a
# developer laptop ADC = whatever `gcloud auth application-default login
# --impersonate-service-account=...` wrote. This file pins no identity by
# string, which is the security property — see ../../gcp_provider.tf for
# the full auth model.

terraform {
  backend "gcs" {
    bucket = "iq9-iac-ops-tf-state-bucket"
    prefix = "terraform/state/foundation/gcp-folders"
  }
}