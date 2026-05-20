# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — yamato / dev / cloudrun — root inputs
# Values supplied by terraform.tfvars (auto-loaded).
# ---------------------------------------------------------------------------------------------------------------------

variable "project_id" {
  description = "Project that owns the Cloud Run service and connector."
  type        = string
}

variable "region" {
  description = "Region for the service and connector."
  type        = string
}

variable "network_name" {
  description = "Name of the app VPC the connector attaches to."
  type        = string
}

variable "connector_name" {
  description = "Serverless VPC Access connector name."
  type        = string
}

variable "connector_cidr" {
  description = "The /28 reserved for the connector."
  type        = string
}

variable "service_name" {
  description = "Cloud Run service name."
  type        = string
}

variable "service_account_id" {
  description = "Account ID for the runtime service account."
  type        = string
}

variable "container_image" {
  description = "Container image to run (placeholder until the app image is built)."
  type        = string
}

variable "db_connection_name" {
  description = "Cloud SQL instance connection name (project:region:instance)."
  type        = string
}

variable "db_name" {
  description = "Application database name."
  type        = string
}

variable "db_user" {
  description = "Application database user."
  type        = string
}

variable "password_secret_id" {
  description = "Secret Manager secret ID holding the DB password."
  type        = string
}
