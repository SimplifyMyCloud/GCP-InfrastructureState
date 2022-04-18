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
  destination = "storage.googleapis.com/{NEEDS_VALUE}"
}

resource "google_project_iam_member" "log_writer" {
  project = "iq9_log_warehouse_00"
  role    = "roles/storage.objectCreator"
  member  = "{NEEDS_VALUE}"
}