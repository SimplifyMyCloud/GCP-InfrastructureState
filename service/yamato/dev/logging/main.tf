# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — yamato / dev / logging
# Thin environment root: instantiates the shared logging module with dev values.
# The reusable shape lives in ../../modules/logging.
# ---------------------------------------------------------------------------------------------------------------------

module "logging" {
  source = "../../modules/logging"

  project_id         = var.project_id
  region             = var.region
  run_service_name   = var.run_service_name
  sql_instance_name  = var.sql_instance_name
  notification_email = var.notification_email

  enable_cloud_armor_alert = var.enable_cloud_armor_alert

  labels = {
    env = "dev"
    app = "yamato"
  }
}

output "app_log_bucket_id" {
  description = "Dedicated app Log Analytics bucket."
  value       = module.logging.app_log_bucket_id
}

output "dashboard_id" {
  description = "Performance & security dashboard ID."
  value       = module.logging.dashboard_id
}

output "security_dashboard_id" {
  description = "SECURITY / attack-view dashboard ID."
  value       = module.logging.security_dashboard_id
}
