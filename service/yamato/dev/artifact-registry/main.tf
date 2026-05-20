# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — yamato / dev / artifact-registry
# Thin environment root: instantiates the shared artifact-registry module with
# dev values. The reusable shape lives in ../../modules/artifact-registry.
# ---------------------------------------------------------------------------------------------------------------------

module "artifact_registry" {
  source = "../../modules/artifact-registry"

  project_id    = var.project_id
  region        = var.region
  repository_id = var.repository_id

  labels = {
    env = "dev"
    app = "yamato"
  }
}

output "repository_url" {
  description = "Docker host/path prefix for tagging and pushing the app image."
  value       = module.artifact_registry.repository_url
}
