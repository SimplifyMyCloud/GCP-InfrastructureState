# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# Logging — gcp-org — org-wide cold archive sink
# ---------------------------------------------------------------------------------------------------------------------
#
# NEW 2026-11-02. Sends EVERY log entry from every folder and project in the Org
# (no filter, include_children) to gs://smc-ops-log-archive (Archive class,
# 365-day delete; bucket in gcp-projects/smc-ops/smc-ops/).
#
# It doesn't intercept: each project still keeps its own _Required (400 days)
# and _Default (30 days) copies. Data Access audit logs are only captured where
# a project turns them on.
#
# The sink writes as its own writer identity, which gets objectCreator on the
# bucket in iam/smc-ops/smc-ops/iam_smc_ops_log_archive_bucket.tf. GCS sinks
# deliver in roughly hourly batches.

resource "google_logging_organization_sink" "smc_org_log_archive" {
  org_id           = "933250405420"
  name             = "smc-org-log-archive"
  description      = "Org-wide cold archive: every log, every folder and project, to gs://smc-ops-log-archive (365 days)"
  destination      = "storage.googleapis.com/smc-ops-log-archive"
  filter           = ""
  include_children = true
  disabled         = false
}
