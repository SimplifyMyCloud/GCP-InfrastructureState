# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — module: artifact-registry
# A single Docker-format Artifact Registry repository, plus the two APIs the
# image pipeline needs (Artifact Registry to store images, Cloud Build to build
# them). Cloud Build *triggers* are intentionally not created here — early on,
# images are pushed with `gcloud builds submit` / `docker push`; wiring a trigger
# to the source repo is a later step once the App Layer exists.
# ---------------------------------------------------------------------------------------------------------------------

# APIs are enabled by the state that uses them (same discipline as the Foundation
# Layer). disable_on_destroy = false so a `terraform destroy` of this state never
# yanks an API out from under another state in the same project.
resource "google_project_service" "artifactregistry" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild" {
  project = var.project_id
  service = "cloudbuild.googleapis.com"

  disable_on_destroy = false
}

# The Docker repository that holds the yamato app image. Cloud Run pulls from
# here; Cloud Build pushes to here.
resource "google_artifact_registry_repository" "this" {
  project       = var.project_id
  location      = var.region
  repository_id = var.repository_id
  format        = "DOCKER"
  description   = var.description
  labels        = var.labels

  depends_on = [google_project_service.artifactregistry]
}
