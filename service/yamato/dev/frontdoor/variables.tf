# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — yamato / dev / frontdoor — root inputs
# Values supplied by terraform.tfvars (auto-loaded).
# ---------------------------------------------------------------------------------------------------------------------

variable "project_id" {
  description = "Project that owns the LB, cert, and IAP config."
  type        = string
}

variable "region" {
  description = "Region of the Cloud Run service the NEG targets."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for front-door resource names."
  type        = string
}

variable "domain" {
  description = "Hostname for the managed SSL certificate."
  type        = string
}

variable "cloud_run_service_name" {
  description = "Cloud Run service name both backends route to."
  type        = string
}
