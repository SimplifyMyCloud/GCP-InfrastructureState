# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — module: artifact-registry
# A single Docker-format Artifact Registry repository, plus the two APIs the
# image pipeline needs (Artifact Registry to store images, Cloud Build to build
# them). Cloud Build *triggers* are intentionally not created here — early on,
# images are pushed with `gcloud builds submit` / `docker push`; wiring a trigger
# to the source repo is a later step once the App Layer exists.
# ---------------------------------------------------------------------------------------------------------------------

# APIs (artifactregistry, cloudbuild) are enabled by the foundation project state,
# foundation/gcp-projects/yamato/dev/ — not here. The Service Layer assumes they
# are already on.

# The Docker repository that holds the yamato app image. Cloud Run pulls from
# here; Cloud Build pushes to here.
resource "google_artifact_registry_repository" "this" {
  project       = var.project_id
  location      = var.region
  repository_id = var.repository_id
  format        = "DOCKER"
  description   = var.description
  labels        = var.labels
}
