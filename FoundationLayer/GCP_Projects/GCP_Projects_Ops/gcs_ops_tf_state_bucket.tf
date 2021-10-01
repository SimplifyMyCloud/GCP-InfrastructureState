# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCS Bucket to host Terraform State files for all environments
# ---------------------------------------------------------------------------------------------------------------------
resource "google_storage_bucket" "tf_state_bucket" {
  name = "iq9-terraform-shared-state-bucket"
  location = "us-west1"
  project  = "iq9-ops-7523"
  storage_class  = "regional"
  versioning {
    enabled = true
  }
}
