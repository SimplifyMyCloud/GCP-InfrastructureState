# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — yamato / dev / logging — inputs
# ---------------------------------------------------------------------------------------------------------------------

variable "project_id" {
  description = "Project that owns the app's logging/monitoring resources."
  type        = string
}

variable "region" {
  description = "Region for the Log Analytics bucket."
  type        = string
}

variable "run_service_name" {
  description = "Cloud Run service name to scope metrics/logs to."
  type        = string
}

variable "sql_instance_name" {
  description = "Cloud SQL instance name (for database_id in metrics)."
  type        = string
}

variable "notification_email" {
  description = "Email address that receives alert notifications."
  type        = string
}
