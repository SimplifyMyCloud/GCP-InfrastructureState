# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCS Bucket to host Terraform State files for all environments
# ---------------------------------------------------------------------------------------------------------------------
resource "google_storage_bucket" "iq9_usage_reporting_bucket" {
  name = "iq9-usage-reporting-bucket"
  location = "us-west1"
  project  = "iq9-ops-7523"
  storage_class  = "regional"
  versioning {
    enabled = true
  }
}
