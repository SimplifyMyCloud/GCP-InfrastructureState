# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# IAM — smc-ops / smc-ops — gs://smc-ops-tf-state bucket IAM
# ---------------------------------------------------------------------------------------------------------------------
#
# NEW (2026-11-02). smc-tf-foundation-sa is read-only at the Org (iam/gcp-org/),
# but even `terraform plan` WRITES to the state bucket: it takes a lock object
# (default.tflock) and releases it. objectAdmin on this one bucket lets the SA
# lock and, during a change window, write state. It can't change the bucket's
# own config or IAM.
#
# The bucket itself lives in gcp-projects/smc-ops/smc-ops/gcp_projects_smc_ops_storage.tf.

resource "google_storage_bucket_iam_member" "tf_state_foundation_sa_object_admin" {
  bucket = "smc-ops-tf-state"
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:smc-tf-foundation-sa@smc-ops.iam.gserviceaccount.com"
}
