# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# IAM — gcp-org — org-wide audit logging config
# ---------------------------------------------------------------------------------------------------------------------
#
# Data Access audit logs (ADMIN_READ, DATA_READ, DATA_WRITE) are ON for every
# service in every project of the Org. Admin Activity logs are always on and
# can't be turned off, so they don't appear here.

resource "google_organization_iam_audit_config" "all_services" {
  org_id  = "933250405420"
  service = "allServices"

  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

import {
  to = google_organization_iam_audit_config.all_services
  id = "933250405420 allServices"
}
