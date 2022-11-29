# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCS Storage Bucket
# GCP Logging Layer - Log Warehouse
# ---------------------------------------------------------------------------------------------------------------------
# log warehouse environment
# ensure the GCS Bucke

resource "google_storage_bucket" "gcs_iq9_log_warehouse" {
  name = "iq9-log-warehouse"
  project = "iq9-log-warehouse-01"
  storage_class = "ARCHIVE"
  location = "us-west1"
  force_destroy = false
  
  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }
}