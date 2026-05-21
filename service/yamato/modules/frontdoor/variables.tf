# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — module: frontdoor — inputs
# ---------------------------------------------------------------------------------------------------------------------

variable "project_id" {
  description = "Project that owns the load balancer, certificate, and IAP config."
  type        = string
}

variable "region" {
  description = "Region of the Cloud Run service the serverless NEG targets."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for all front-door resource names, e.g. iq9-dev-yamato. Resource-type suffixes are appended (-ip, -cert, -neg, ...)."
  type        = string
}

variable "domain" {
  description = "Fully-qualified hostname served by the managed SSL certificate, e.g. yamato-dev.iq9.io."
  type        = string
}

variable "cloud_run_service_name" {
  description = "Name of the Cloud Run service (in var.region) that both backends route to."
  type        = string
}

variable "wiki_path_prefix" {
  description = "URL path prefix routed to the IAP-protected backend. Everything else goes to the public landing backend."
  type        = string
  default     = "/wiki"
}

variable "iap_members" {
  description = "Principals allowed through IAP (roles/iap.httpsResourceAccessor) on the wiki backend. domain:iq9.io = anyone with an @iq9.io identity."
  type        = list(string)
  default     = ["domain:iq9.io"]
}

variable "iap_enabled" {
  description = "Whether IAP is enforced on the wiki backend. Normally true; set false to isolate IAP from other LB issues during debugging."
  type        = bool
  default     = true
}

variable "enable_http_redirect" {
  description = "Also stand up a port-80 listener that 301-redirects to HTTPS."
  type        = bool
  default     = true
}
