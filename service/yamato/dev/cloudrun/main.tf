# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — yamato / dev / cloudrun
# Thin environment root: instantiates the shared cloudrun module with dev values.
# The reusable shape lives in ../../modules/cloudrun.
# ---------------------------------------------------------------------------------------------------------------------

module "cloudrun" {
  source = "../../modules/cloudrun"

  project_id = var.project_id
  region     = var.region

  network_name = var.network_name
  subnet_name  = var.subnet_name

  service_name       = var.service_name
  service_account_id = var.service_account_id
  container_image    = var.container_image

  db_connection_name = var.db_connection_name
  db_name            = var.db_name
  db_user            = var.db_user
  password_secret_id = var.password_secret_id

  labels = {
    env = "dev"
    app = "yamato"
  }
}

output "service_name" {
  description = "Cloud Run service name (feeds the frontdoor serverless NEG)."
  value       = module.cloudrun.service_name
}

output "runtime_service_account_email" {
  description = "Runtime SA email."
  value       = module.cloudrun.runtime_service_account_email
}
