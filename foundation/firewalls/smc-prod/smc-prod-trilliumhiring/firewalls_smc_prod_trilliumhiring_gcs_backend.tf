# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# firewalls — smc-prod / smc-prod-trilliumhiring — Terraform State (GCS backend)
# ---------------------------------------------------------------------------------------------------------------------
#
# State for this directory lives at the GCS path that mirrors this git path:
#   gs://smc-ops-tf-state/terraform/state/foundation/firewalls/smc-prod/smc-prod-trilliumhiring/default.tfstate
#
# No identity is pinned here. Application Default Credentials decide who runs
# Terraform — see the repo-root gcp_provider.tf.

terraform {
  backend "gcs" {
    bucket = "smc-ops-tf-state"
    prefix = "terraform/state/foundation/firewalls/smc-prod/smc-prod-trilliumhiring"
  }
}
