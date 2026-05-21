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
  description = "Public Cloud Run service name the public backend routes to."
  type        = string
}

variable "wiki_service_name" {
  description = "IAP-gated wiki Cloud Run service name the wiki backend routes to."
  type        = string
}

variable "iap_members" {
  description = "Principals granted IAP access to the /wiki backend (roles/iap.httpsResourceAccessor)."
  type        = list(string)
}

variable "iap_enabled" {
  description = "Whether IAP is enforced on the wiki backend (set false only for debugging)."
  type        = bool
  default     = true
}
