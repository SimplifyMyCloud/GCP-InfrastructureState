# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — yamato / dev / cloudsql — Terraform State (GCS backend)
# ---------------------------------------------------------------------------------------------------------------------
#
# State for this directory's resources lives in:
#   gs://iq9-iac-ops-tf-state-bucket/terraform/state/service/yamato/dev/cloudsql/
#
# This state contains the DB password (random_password + secret version) in plain
# text — the state bucket's access controls (uniform bucket-level access, public
# access prevention, restricted IAM) are what protect it. Identity is resolved by
# ADC at runtime; nothing is pinned here. See ../../../gcp_provider.tf.

terraform {
  backend "gcs" {
    bucket = "iq9-iac-ops-tf-state-bucket"
    prefix = "terraform/state/service/yamato/dev/cloudsql"
  }
}
