# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Projects
# ensures GCP Projects per Infrastructure Environment
# for the Foundation Layer development environment, ensure a random prefix is included to avoid naming collisions
# and naming reservations.  GCP Projects are long lived naming reservations.
# ---------------------------------------------------------------------------------------------------------------------
# log warehouse environment
# ensure the GCP Org log sync

resource "google_logging_organization_sink" "iq9_org_log_sync" {
  name        = "iq9_org_level_log_sync"
  description = "GCP iq9 Org level log sync"
  org_id      = "447686549950"
  destination = "storage.googleapis.com/iq9-log-warehouse"
}

resource "google_logging_organization_bucket_config" "iq9_org_sync_log_bucket" {
  organization = "447686549950"
  location = "global"
  retention_days = 48
  bucket_id = "iq9-log-warehouse"
}

#resource "google_project_iam_member" "log_writer" {
#  project = "iq9_log_warehouse_01"
#  role    = "roles/storage.objectCreator"
#  member  = "850153025254-compute@developer.gserviceaccount.com"
#}