# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — module: logging — inputs
# ---------------------------------------------------------------------------------------------------------------------

variable "project_id" {
  description = "Project that owns the app's logging/monitoring resources."
  type        = string
}

variable "region" {
  description = "Region for the Log Analytics bucket."
  type        = string
  default     = "us-west1"
}

variable "run_service_name" {
  description = "Cloud Run service name to scope app metrics/logs to (e.g. iq9-run-dev-yamato)."
  type        = string
}

variable "sql_instance_name" {
  description = "Cloud SQL instance name (e.g. yamato-dev). Combined with project_id to form database_id for metrics."
  type        = string
}

variable "notification_email" {
  description = "Email address that receives alert notifications."
  type        = string
}

# --- Security ------------------------------------------------------------------------------------------------------

variable "enable_data_access_audit_logs" {
  description = "Enable Data Access audit logs (DATA_READ/DATA_WRITE) on this project for Cloud SQL + Secret Manager. Foundation leaves these off org-wide; this opts the app project in."
  type        = bool
  default     = true
}

variable "app_log_retention_days" {
  description = "Retention for the dedicated app Log Analytics bucket."
  type        = number
  default     = 30
}

# --- Alert thresholds (tune after first data) ----------------------------------------------------------------------

variable "latency_threshold_ms" {
  description = "Alert when Cloud Run p95 request latency exceeds this (milliseconds)."
  type        = number
  default     = 2000
}

variable "error_5xx_threshold" {
  description = "Alert when the Cloud Run 5xx rate exceeds this (requests/second)."
  type        = number
  default     = 1
}

variable "sql_cpu_threshold" {
  description = "Alert when Cloud SQL CPU utilization exceeds this (fraction 0-1)."
  type        = number
  default     = 0.8
}

variable "app_error_threshold" {
  description = "Alert when app ERROR-severity log events exceed this count per 5 min."
  type        = number
  default     = 10
}

variable "secret_access_threshold" {
  description = "Alert when Secret Manager AccessSecretVersion calls exceed this count per 5 min (anomalous access)."
  type        = number
  default     = 50
}

# --- Security / attack thresholds --------------------------------------------------------------------------------

variable "cloud_armor_block_threshold" {
  description = "Alert when Cloud Armor blocked requests exceed this count per 5 min (active scan/injection at the edge)."
  type        = number
  default     = 20
}

variable "enable_cloud_armor_alert" {
  description = "Create the Cloud Armor blocks ALERT policy. A log-based metric's descriptor only registers with Monitoring after it has logged >=1 matching entry, so a fresh metric with zero data can't have an alert built on it. Keep false until Cloud Armor has produced at least one DENY (the metric + dashboard tile work regardless); then flip true and re-apply."
  type        = bool
  default     = false
}

variable "denied_api_threshold" {
  description = "Alert when PERMISSION_DENIED API calls exceed this count per 5 min (credentials hammering the IAM wall)."
  type        = number
  default     = 10
}

variable "sa_token_mint_threshold" {
  description = "Alert when SA access-token mints (GenerateAccessToken) exceed this count per 5 min (possible SA-takeover/impersonation)."
  type        = number
  default     = 20
}

variable "sa_key_create_threshold" {
  description = "Alert when SA key-creation ATTEMPTS exceed this count per 5 min. Default 0 = any attempt fires (org policy blocks these; a hit is always suspicious)."
  type        = number
  default     = 0
}

variable "labels" {
  description = "Resource labels (e.g. env, app)."
  type        = map(string)
  default     = {}
}
