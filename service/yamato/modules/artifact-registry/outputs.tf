# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — module: artifact-registry — outputs
# ---------------------------------------------------------------------------------------------------------------------

output "repository_id" {
  description = "The repository ID (name)."
  value       = google_artifact_registry_repository.this.repository_id
}

output "repository_name" {
  description = "The fully-qualified repository resource name."
  value       = google_artifact_registry_repository.this.name
}

output "repository_url" {
  description = "Docker registry host/path prefix for tagging images, e.g. us-west1-docker.pkg.dev/<project>/<repo>."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.this.repository_id}"
}
