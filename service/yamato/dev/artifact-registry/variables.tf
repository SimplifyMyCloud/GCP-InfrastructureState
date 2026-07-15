# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — yamato / dev / artifact-registry — root inputs
# Values supplied by terraform.tfvars (auto-loaded).
# ---------------------------------------------------------------------------------------------------------------------

variable "project_id" {
  description = "Project that owns the Artifact Registry repository."
  type        = string
}

variable "region" {
  description = "Region for the repository."
  type        = string
}

variable "repository_id" {
  description = "Artifact Registry repository ID (Docker)."
  type        = string
}
