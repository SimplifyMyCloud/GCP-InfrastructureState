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

# No writer-identity IAM grant is needed: the sink routes to a log bucket in the
# SAME project, which Cloud Logging delivers internally. (writer_identity comes back
# empty for same-project log-bucket sinks — there is nothing to grant.)

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

# --- Layer 4: attack-surface metrics (light up during a red-team scan) ----------------------------------------------
#
# These are the "the defense is working" signals for the gamilas demo. Each maps to a wall
# the attacker hits: Cloud Armor at the edge, IAM at the control plane.

# Cloud Armor denials at the LB (Profile 1's blocked scan/injection payloads). Requires
# Cloud Armor on the front door (service/yamato/dev/frontdoor) + LB logging (already on).
resource "google_logging_metric" "cloud_armor_blocked" {
  project = var.project_id
  name    = "yamato/cloud_armor_blocked"
  filter  = "resource.type=\"http_load_balancer\" AND jsonPayload.enforcedSecurityPolicy.outcome=\"DENY\""

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "INT64"
    unit         = "1"
    display_name = "yamato Cloud Armor blocked requests"
  }
}

# Denied API calls — PERMISSION_DENIED (google.rpc.Code 7) in audit logs. The IAM wall:
# every time the stolen-creds attacker (Profile 2) is told "no", it lands here.
resource "google_logging_metric" "denied_api_calls" {
  project = var.project_id
  name    = "yamato/denied_api_calls"
  filter  = "protoPayload.@type=\"type.googleapis.com/google.cloud.audit.AuditLog\" AND protoPayload.status.code=7"

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "INT64"
    unit         = "1"
    display_name = "yamato denied API calls (PERMISSION_DENIED)"
  }
}

# Service-account token minting via IAM Credentials (GenerateAccessToken). The core
# SA-takeover / impersonation signal — a spike means someone is assuming SAs.
resource "google_logging_metric" "sa_token_mints" {
  project = var.project_id
  name    = "yamato/sa_token_mints"
  filter  = "protoPayload.serviceName=\"iamcredentials.googleapis.com\" AND protoPayload.methodName=\"GenerateAccessToken\""

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "INT64"
    unit         = "1"
    display_name = "yamato SA access-token mints"
  }
}

# Service-account KEY creation attempts. Org policy iam.disableServiceAccountKeyCreation
# blocks these — so any hit is the attacker rattling a locked door (and likely also
# shows up in denied_api_calls). Should be flat at zero in normal operation.
resource "google_logging_metric" "sa_key_create_attempts" {
  project = var.project_id
  name    = "yamato/sa_key_create_attempts"
  filter  = "protoPayload.methodName=\"google.iam.admin.v1.CreateServiceAccountKey\""

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "INT64"
    unit         = "1"
    display_name = "yamato SA key-creation attempts"
  }
}
