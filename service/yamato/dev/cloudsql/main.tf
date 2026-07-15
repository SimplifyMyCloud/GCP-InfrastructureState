# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — yamato / dev / cloudsql
# Thin environment root: instantiates the shared cloudsql module with dev values.
# The reusable shape lives in ../../modules/cloudsql.
# ---------------------------------------------------------------------------------------------------------------------

module "cloudsql" {
  source = "../../modules/cloudsql"

  project_id         = var.project_id
  region             = var.region
  network_id         = var.network_id
  instance_name      = var.instance_name
  database_name      = var.database_name
  db_user            = var.db_user
  password_secret_id = var.password_secret_id

  # dev sizing: smallest shared-core, single zone, no HA (module defaults make
  # these explicit, repeated here as documentation of the dev posture).
  tier              = "db-f1-micro"
  availability_type = "ZONAL"

  labels = {
    env = "dev"
    app = "yamato"
  }
}

output "connection_name" {
  description = "Instance connection name for the Cloud SQL connector (feeds the cloudrun state)."
  value       = module.cloudsql.connection_name
}

output "private_ip_address" {
  description = "Instance private IP."
  value       = module.cloudsql.private_ip_address
}

output "password_secret_id" {
  description = "Secret Manager secret ID for the DB password (feeds the cloudrun state)."
  value       = module.cloudsql.password_secret_id
}
