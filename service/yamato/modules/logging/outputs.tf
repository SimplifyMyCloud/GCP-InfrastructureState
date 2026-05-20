# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — module: logging — outputs
# ---------------------------------------------------------------------------------------------------------------------

output "app_log_bucket_id" {
  description = "Resource ID of the dedicated app Log Analytics bucket."
  value       = google_logging_project_bucket_config.app.id
}

output "notification_channel_id" {
  description = "Monitoring notification channel ID used by the alert policies."
  value       = google_monitoring_notification_channel.email.id
}

output "dashboard_id" {
  description = "Monitoring dashboard ID."
  value       = google_monitoring_dashboard.yamato.id
}
