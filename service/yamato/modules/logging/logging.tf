# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — module: logging — logs side
# ---------------------------------------------------------------------------------------------------------------------
#
# The per-app logging surface for yamato (owned by the app's dev/SRE team, NOT
# foundation). Three layers of security logging + the log-based metrics that feed
# the performance & security alerts in monitoring.tf:
#
#   1. Data Access audit logs ON for this project (Cloud SQL + Secret Manager) —
#      foundation leaves these off org-wide; the app opts itself in.
#   2. A dedicated Log Analytics bucket capturing the app's own logs (Cloud Run +
#      load balancer + data-access) for queryable, app-scoped retention.
#   3. Log-based metrics for app errors, Secret Manager access, and IAP denials.
# ---------------------------------------------------------------------------------------------------------------------

# --- Layer 1: Data Access audit logs on the app project ------------------------------------------------------------
# Enables who-read/who-wrote logging for the two security-sensitive services this
# app uses. These feed the security bucket/metrics and the foundation security sink.
resource "google_project_iam_audit_config" "cloudsql" {
  count = var.enable_data_access_audit_logs ? 1 : 0

  project = var.project_id
  service = "cloudsql.googleapis.com"

  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

resource "google_project_iam_audit_config" "secretmanager" {
  count = var.enable_data_access_audit_logs ? 1 : 0

  project = var.project_id
  service = "secretmanager.googleapis.com"

  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

# --- Layer 2: dedicated Log Analytics bucket + sink ----------------------------------------------------------------
# A queryable, app-scoped log bucket (Log Analytics enabled) with its own retention,
# separate from _Default. The sink routes the app's Cloud Run logs, its load-balancer
# logs, and data-access audit logs into it.
resource "google_logging_project_bucket_config" "app" {
  project        = var.project_id
  location       = var.region
  bucket_id      = "yamato-app-logs"
  description    = "yamato app logs (Cloud Run + LB + data access) — Log Analytics enabled."
  retention_days = var.app_log_retention_days

  enable_analytics = true
}

resource "google_logging_project_sink" "app" {
  project     = var.project_id
  name        = "yamato-app-logs-sink"
  destination = "logging.googleapis.com/projects/${var.project_id}/locations/${var.region}/buckets/${google_logging_project_bucket_config.app.bucket_id}"

  filter = <<-EOT
    (resource.type="cloud_run_revision" AND resource.labels.service_name="${var.run_service_name}")
    OR resource.type="http_load_balancer"
    OR log_id("cloudaudit.googleapis.com/data_access")
  EOT

  unique_writer_identity = true
}

# The sink's writer identity needs bucketWriter to deliver into the log bucket.
resource "google_project_iam_member" "app_sink_bucket_writer" {
  project = var.project_id
  role    = "roles/logging.bucketWriter"
  member  = google_logging_project_sink.app.writer_identity
}

# --- Layer 3: log-based metrics ------------------------------------------------------------------------------------

# App ERROR-severity events (reliability/performance signal).
resource "google_logging_metric" "app_errors" {
  project = var.project_id
  name    = "yamato/app_errors"
  filter  = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${var.run_service_name}\" AND severity>=ERROR"

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "INT64"
    unit         = "1"
    display_name = "yamato app errors"
  }
}

# Secret Manager access (security signal — depends on Data Access audit logs above).
resource "google_logging_metric" "secret_access" {
  project = var.project_id
  name    = "yamato/secret_access"
  filter  = "protoPayload.serviceName=\"secretmanager.googleapis.com\" AND protoPayload.methodName=\"google.cloud.secretmanager.v1.SecretManagerService.AccessSecretVersion\""

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "INT64"
    unit         = "1"
    display_name = "yamato secret accesses"
  }
}

# IAP / authorization denials at the front door (security signal). 403s at the
# external LB are the observable proxy for IAP-denied requests to /wiki.
resource "google_logging_metric" "iap_denied" {
  project = var.project_id
  name    = "yamato/iap_denied"
  filter  = "resource.type=\"http_load_balancer\" AND httpRequest.status=403"

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "INT64"
    unit         = "1"
    display_name = "yamato IAP/front-door denials (403)"
  }
}
