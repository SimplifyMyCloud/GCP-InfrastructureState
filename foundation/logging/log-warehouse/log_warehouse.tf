# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer — Logging — Log Warehouse
# ---------------------------------------------------------------------------------------------------------------------
#
# The cold-archive DESTINATIONS for the org-wide log sinks. A dedicated project
# under the `logs` folder holds THREE GCS ARCHIVE buckets that together capture
# everything the org emits, partitioned by category:
#
#   audit     — admin/system change trail        (who changed what)
#   security  — access/denial/data-access logs    (who tried/accessed what)
#   archive   — everything else                   (app/infra/general catch-all)
#
# The three sinks (../log-sinks) use mutually-exclusive filters, so their union is
# "everything" with no duplication. ARCHIVE class + a 365-day lifecycle keep raw
# capture cheap. Deliberately separate from observability (the `ops` folder); the
# nice per-app querying/dashboards live in the Service Layer.
#
# All values hardcoded per the Foundation-layer convention.
# ---------------------------------------------------------------------------------------------------------------------

# The project that owns the archive buckets. Parented to the bootstrap-created
# `logs` folder (473370836814), billed to the iq9 billing account.
# deletion_policy = "PREVENT" so a stray destroy can't wipe the archives.
resource "google_project" "log_warehouse" {
  name       = "iq9-log-warehouse-01"
  project_id = "iq9-log-warehouse-01"

  folder_id       = "473370836814"
  billing_account = "000000-000002-6D3BF8"

  auto_create_network = false
  deletion_policy     = "PREVENT"

  labels = {
    env  = "logs"
    role = "log-warehouse"
  }
}

# Cloud Storage API — required before the buckets can be created.
resource "google_project_service" "storage" {
  project = google_project.log_warehouse.project_id
  service = "storage.googleapis.com"

  disable_on_destroy = false
}

# --- Audit bucket: admin/system change trail -----------------------------------------------------------------------
resource "google_storage_bucket" "audit" {
  name     = "iq9-log-audit"
  project  = google_project.log_warehouse.project_id
  location = "us-west1"

  storage_class               = "ARCHIVE"
  force_destroy               = false
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.storage]
}

# --- Security bucket: access / denial / data-access -----------------------------------------------------------------
resource "google_storage_bucket" "security" {
  name     = "iq9-log-security"
  project  = google_project.log_warehouse.project_id
  location = "us-west1"

  storage_class               = "ARCHIVE"
  force_destroy               = false
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.storage]
}

# --- Archive bucket: everything else (catch-all) -------------------------------------------------------------------
resource "google_storage_bucket" "archive" {
  name     = "iq9-log-archive"
  project  = google_project.log_warehouse.project_id
  location = "us-west1"

  storage_class               = "ARCHIVE"
  force_destroy               = false
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.storage]
}
