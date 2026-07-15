# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer — Logging — Org Log Sink — Terraform State (GCS backend)
# ---------------------------------------------------------------------------------------------------------------------
#
# State for this directory's resources lives in:
#   gs://iq9-iac-ops-tf-state-bucket/terraform/state/foundation/logging/log-sinks/
#
# Same state bucket as every other workspace in this repo; prefix mirrors the git
# path. Identity is resolved by ADC at runtime — see ../../../gcp_provider.tf.

terraform {
  backend "gcs" {
    bucket = "iq9-iac-ops-tf-state-bucket"
    prefix = "terraform/state/foundation/logging/log-sinks"
  }
}
