# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Networks — bakery — Terraform State (GCS backend)
# ---------------------------------------------------------------------------------------------------------------------
#
# State for this directory's resources lives in:
#   gs://iq9-iac-ops-tf-state-bucket/terraform/state/foundation/networks/bakery/
#
# Same bucket and same auth model as every other foundation state: uniform
# bucket-level access, public access prevention, versioning; identity resolved
# at runtime by ADC (no SA pinned by string here) — see ../../../gcp_provider.tf.

terraform {
  backend "gcs" {
    bucket = "iq9-iac-ops-tf-state-bucket"
    prefix = "terraform/state/foundation/networks/bakery"
  }
}
