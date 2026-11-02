# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Folders — smc-ops — Terraform State (GCS backend)
# ---------------------------------------------------------------------------------------------------------------------
#
# State for this directory lives at the GCS path that mirrors this git path:
#   gs://smc-ops-tf-state/terraform/state/foundation/gcp-folders/smc-ops/default.tfstate
#
# No identity is pinned here. Application Default Credentials decide who runs
# Terraform — see the repo-root gcp_provider.tf.

terraform {
  backend "gcs" {
    bucket = "smc-ops-tf-state"
    prefix = "terraform/state/foundation/gcp-folders/smc-ops"
  }
}
