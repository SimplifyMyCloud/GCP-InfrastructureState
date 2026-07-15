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

variable "enable_cloud_armor" {
  description = "Attach the Cloud Armor edge policy (OWASP WAF + rate limiting + adaptive protection) to the front door."
  type        = bool
  default     = true
}

variable "cloud_armor_preview" {
  description = "Cloud Armor PREVIEW (log-only) vs ENFORCE (block). false = enforce. Flip true if you need to validate rules without blocking."
  type        = bool
  default     = false
}

variable "enable_adaptive_protection" {
  description = "Enable Cloud Armor Adaptive Protection (L7 DDoS). Set false if this project isn't enrolled in Cloud Armor Enterprise."
  type        = bool
  default     = true
}
