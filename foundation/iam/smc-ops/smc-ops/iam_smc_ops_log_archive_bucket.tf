# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# IAM — smc-ops / smc-ops — gs://smc-ops-log-archive bucket IAM
# ---------------------------------------------------------------------------------------------------------------------
#
# NEW 2026-11-02. Lets the org-wide sink `smc-org-log-archive` (logging/gcp-org/)
# write into the cold archive bucket (gcp-projects/smc-ops/smc-ops/).
#
# The member is the sink's writer identity: the Org's Cloud Logging service agent,
# shared by every org-level sink. It's hardcoded from the sink's `writer_identity`
# after the sink was created. objectCreator lets it add objects only; it can't
# read, overwrite or delete them.

resource "google_storage_bucket_iam_member" "log_archive_org_sink_object_creator" {
  bucket = "smc-ops-log-archive"
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:service-org-933250405420@gcp-sa-logging.iam.gserviceaccount.com"
}
