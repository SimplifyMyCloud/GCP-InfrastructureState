# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — yamato / dev / cloudsql — root inputs
# Values supplied by terraform.tfvars (auto-loaded).
# ---------------------------------------------------------------------------------------------------------------------

variable "project_id" {
  description = "Project that owns the Cloud SQL instance."
  type        = string
}

variable "region" {
  description = "Region for the instance."
  type        = string
}

variable "network_id" {
  description = "Full resource URI of the app VPC (private IP attaches here)."
  type        = string
}

variable "instance_name" {
  description = "Cloud SQL instance name (deterministic)."
  type        = string
}

variable "database_name" {
  description = "Application database name."
  type        = string
}

variable "db_user" {
  description = "Application database user."
  type        = string
}

variable "password_secret_id" {
  description = "Secret Manager secret ID for the DB password."
  type        = string
}
