# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — module: artifact-registry — inputs
# ---------------------------------------------------------------------------------------------------------------------

variable "project_id" {
  description = "Project that owns the Artifact Registry repository (e.g. iq9-gcp-dev-yamato)."
  type        = string
}

variable "region" {
  description = "Region for the Artifact Registry repository. Keep it co-located with Cloud Run."
  type        = string
}

variable "repository_id" {
  description = "Artifact Registry repository ID (the repo name, e.g. yamato). Docker format."
  type        = string
}

variable "description" {
  description = "Human-readable description shown on the repository."
  type        = string
  default     = "Container images for the yamato wiki app."
}

variable "labels" {
  description = "Resource labels applied to the repository (e.g. env, app)."
  type        = map(string)
  default     = {}
}
