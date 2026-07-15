# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — module: cloudsql — outputs
# ---------------------------------------------------------------------------------------------------------------------

output "instance_name" {
  description = "The Cloud SQL instance name."
  value       = google_sql_database_instance.this.name
}

output "connection_name" {
  description = "Instance connection name (project:region:instance) used by the Cloud SQL connector."
  value       = google_sql_database_instance.this.connection_name
}

output "private_ip_address" {
  description = "The instance's private IP (from the PSA range)."
  value       = google_sql_database_instance.this.private_ip_address
}

output "database_name" {
  description = "Application database name."
  value       = google_sql_database.this.name
}

output "db_user" {
  description = "Application database user."
  value       = google_sql_user.app.name
}

output "password_secret_id" {
  description = "Secret Manager secret ID holding the DB password."
  value       = google_secret_manager_secret.db_password.secret_id
}
