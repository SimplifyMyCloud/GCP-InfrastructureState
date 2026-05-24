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
  description = "Name of the PUBLIC Cloud Run service the public backend routes to."
  type        = string
}

variable "wiki_service_name" {
  description = "Name of the IAP-gated wiki Cloud Run service the wiki backend routes to (a separate service so IAP can't leak onto the public path)."
  type        = string
}

variable "wiki_path_prefix" {
  description = "URL path prefix routed to the IAP-protected backend. Everything else goes to the public landing backend."
  type        = string
  default     = "/wiki"
}

variable "noc_path_prefix" {
  description = "URL path prefix for the internal NOC page ('Yamato Defense Command'), routed to the SAME IAP-gated backend as the wiki so it is private to the IAP members. Served by the app's /noc handler."
  type        = string
  default     = "/noc"
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

# --- Cloud Armor (edge WAF + rate limiting) ------------------------------------------------------------------------

variable "enable_cloud_armor" {
  description = "Attach a Cloud Armor security policy (OWASP WAF + per-IP rate limiting + adaptive protection) to both backend services."
  type        = bool
  default     = true
}

variable "cloud_armor_preview" {
  description = "Run every Cloud Armor rule in PREVIEW (log what WOULD be blocked, do NOT block). false = ENFORCE (actually block). Flip to false for the live attack demo."
  type        = bool
  default     = false
}

variable "waf_sensitivity" {
  description = "Sensitivity (1-4) for the OWASP preconfigured WAF rules. 1 = fewest false positives; higher catches more but risks blocking legit traffic."
  type        = number
  default     = 1
}

variable "enable_adaptive_protection" {
  description = "Enable Cloud Armor Adaptive Protection (L7 DDoS ML detection). Set false if the project isn't enrolled in Cloud Armor Enterprise and the apply complains — the WAF + rate-limit rules are independent of this."
  type        = bool
  default     = true
}

variable "rate_limit_count" {
  description = "Requests allowed per source IP per rate_limit_interval_sec before the rate-based ban triggers."
  type        = number
  default     = 100
}

variable "rate_limit_interval_sec" {
  description = "Sliding window (seconds) for the rate limit count."
  type        = number
  default     = 60
}

variable "rate_limit_ban_duration_sec" {
  description = "How long (seconds) a source IP is banned once it exceeds the rate limit."
  type        = number
  default     = 300
}
