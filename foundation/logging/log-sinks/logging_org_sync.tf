# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer — Logging — Org Log Sinks
# ---------------------------------------------------------------------------------------------------------------------
#
# THREE organization-level aggregated sinks (include_children) that copy logs from
# every project in the org into the cold-archive buckets created by ../log-warehouse.
# Filters are mutually exclusive, so the union is "capture everything" with no
# duplication:
#
#   audit     activity + system_event                       -> iq9-log-audit
#   security  data_access + policy + access_transparency     -> iq9-log-security
#   archive   NOT any of the above (everything else)         -> iq9-log-archive
#
# ADDITIVE: logs still flow to each project's _Default bucket for live debugging;
# these sinks only mirror to immutable archive.
#
# Org-scoped. The applying identity needs, at the ORGANIZATION scope (933250405420):
# roles/logging.configWriter and roles/resourcemanager.organizationViewer. Apply
# ../log-warehouse FIRST — the bucket IAM bindings below reference those buckets.
#
# All values hardcoded per the Foundation-layer convention.
# ---------------------------------------------------------------------------------------------------------------------

# --- Audit: admin/system change trail ------------------------------------------------------------------------------
resource "google_logging_organization_sink" "audit" {
  name        = "iq9-org-sink-audit"
  description = "Org-wide audit logs (admin activity + system event) -> iq9-log-audit."
  org_id      = "933250405420"

  # Org sinks always get a unique writer identity automatically (no
  # unique_writer_identity arg — that's project-sink-only). Available as
  # .writer_identity for the bucket grant below.
  include_children = true

  destination = "storage.googleapis.com/iq9-log-audit"

  filter = <<-EOT
    log_id("cloudaudit.googleapis.com/activity")
    OR log_id("cloudaudit.googleapis.com/system_event")
  EOT
}

resource "google_storage_bucket_iam_member" "audit_writer" {
  bucket = "iq9-log-audit"
  role   = "roles/storage.objectCreator"
  member = google_logging_organization_sink.audit.writer_identity
}

# --- Security: access / denial / data-access -----------------------------------------------------------------------
resource "google_logging_organization_sink" "security" {
  name        = "iq9-org-sink-security"
  description = "Org-wide security logs (data access + policy denied + access transparency) -> iq9-log-security."
  org_id      = "933250405420"

  # Org sinks always get a unique writer identity automatically (no
  # unique_writer_identity arg — that's project-sink-only). Available as
  # .writer_identity for the bucket grant below.
  include_children = true

  destination = "storage.googleapis.com/iq9-log-security"

  filter = <<-EOT
    log_id("cloudaudit.googleapis.com/data_access")
    OR log_id("cloudaudit.googleapis.com/policy")
    OR log_id("cloudaudit.googleapis.com/access_transparency")
  EOT
}

resource "google_storage_bucket_iam_member" "security_writer" {
  bucket = "iq9-log-security"
  role   = "roles/storage.objectCreator"
  member = google_logging_organization_sink.security.writer_identity
}

# --- Archive: everything else (catch-all) --------------------------------------------------------------------------
# The complement of the audit + security filters, so the three sinks partition all
# org logs with no overlap and no gaps.
resource "google_logging_organization_sink" "archive" {
  name        = "iq9-org-sink-archive"
  description = "Org-wide catch-all (everything not routed to audit/security) -> iq9-log-archive."
  org_id      = "933250405420"

  # Org sinks always get a unique writer identity automatically (no
  # unique_writer_identity arg — that's project-sink-only). Available as
  # .writer_identity for the bucket grant below.
  include_children = true

  destination = "storage.googleapis.com/iq9-log-archive"

  filter = <<-EOT
    NOT (
      log_id("cloudaudit.googleapis.com/activity")
      OR log_id("cloudaudit.googleapis.com/system_event")
      OR log_id("cloudaudit.googleapis.com/data_access")
      OR log_id("cloudaudit.googleapis.com/policy")
      OR log_id("cloudaudit.googleapis.com/access_transparency")
    )
  EOT
}

resource "google_storage_bucket_iam_member" "archive_writer" {
  bucket = "iq9-log-archive"
  role   = "roles/storage.objectCreator"
  member = google_logging_organization_sink.archive.writer_identity
}
