# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — yamato / dev / cloudrun — root inputs
# Values supplied by terraform.tfvars (auto-loaded).
# ---------------------------------------------------------------------------------------------------------------------

variable "project_id" {
  description = "Project that owns the Cloud Run service."
  type        = string
}

variable "region" {
  description = "Region for the Cloud Run service."
  type        = string
}

variable "network_name" {
  description = "Name of the app VPC (Cloud Run attaches via Direct VPC egress)."
  type        = string
}

variable "subnet_name" {
  description = "Subnet the Cloud Run service draws Direct VPC egress IPs from."
  type        = string
}

variable "service_name" {
  description = "Cloud Run service name (the public one)."
  type        = string
}

variable "wiki_service_name" {
  description = "Name of the IAP-gated wiki Cloud Run service (serves /wiki)."
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
