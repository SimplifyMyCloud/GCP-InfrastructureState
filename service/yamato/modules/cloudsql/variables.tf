# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — module: cloudsql — inputs
# ---------------------------------------------------------------------------------------------------------------------

variable "project_id" {
  description = "Project that owns the Cloud SQL instance (e.g. iq9-gcp-dev-yamato)."
  type        = string
}

variable "region" {
  description = "Region for the instance."
  type        = string
}

variable "network_id" {
  description = "Full resource URI of the VPC the instance attaches to via private IP, e.g. projects/<project>/global/networks/<vpc>. The PSA peering on this VPC must already exist (created by the Foundation Layer network state)."
  type        = string
}

variable "instance_name" {
  description = "Cloud SQL instance name. Deterministic (no random suffix) so dependents can derive the connection name. Note: a deleted instance name cannot be reused for ~7 days."
  type        = string
}

variable "database_version" {
  description = "Postgres engine version."
  type        = string
  default     = "POSTGRES_16"
}

variable "tier" {
  description = "Machine tier. db-f1-micro is the smallest shared-core option, right for dev."
  type        = string
  default     = "db-f1-micro"
}

variable "edition" {
  description = "Cloud SQL edition. ENTERPRISE supports shared-core tiers like db-f1-micro."
  type        = string
  default     = "ENTERPRISE"
}

variable "availability_type" {
  description = "ZONAL (single zone, no HA) or REGIONAL (HA). Dev uses ZONAL."
  type        = string
  default     = "ZONAL"
}

variable "disk_size_gb" {
  description = "Initial data disk size in GB. Autoresize is on, so this is a floor."
  type        = number
  default     = 10
}

variable "disk_type" {
  description = "PD_SSD or PD_HDD."
  type        = string
  default     = "PD_SSD"
}

variable "backup_start_time" {
  description = "Daily automated-backup start time, HH:MM UTC."
  type        = string
  default     = "03:00"
}

variable "deletion_protection" {
  description = "Terraform-level deletion protection on the instance. True blocks `terraform destroy` from removing the DB."
  type        = bool
  default     = true
}

variable "database_name" {
  description = "Application database created on the instance."
  type        = string
  default     = "yamato"
}

variable "db_user" {
  description = "Application database user (built-in/password auth)."
  type        = string
  default     = "yamato_app"
}

variable "password_secret_id" {
  description = "Secret Manager secret ID that stores the generated DB password."
  type        = string
}

variable "labels" {
  description = "Resource labels applied to the instance (e.g. env, app)."
  type        = map(string)
  default     = {}
}
