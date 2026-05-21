# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — module: cloudrun — inputs
# ---------------------------------------------------------------------------------------------------------------------

variable "project_id" {
  description = "Project that owns the Cloud Run service."
  type        = string
}

variable "region" {
  description = "Region for the Cloud Run service."
  type        = string
}

# --- Direct VPC egress (Cloud Run -> app subnet) -------------------------------------------------------------------

variable "network_name" {
  description = "Name of the app VPC the Cloud Run service attaches to via Direct VPC egress (e.g. iq9-vpc-dev-yamato)."
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet the Cloud Run service draws Direct VPC egress IPs from (e.g. iq9-subnet-dev-yamato)."
  type        = string
}

# --- Runtime identity -----------------------------------------------------------------------------------------------

variable "service_account_id" {
  description = "Account ID (local part) for the Cloud Run runtime service account."
  type        = string
}

# --- The service ----------------------------------------------------------------------------------------------------

variable "service_name" {
  description = "Cloud Run service name (the public one)."
  type        = string
}

variable "wiki_service_name" {
  description = "Name of the second, IAP-gated Cloud Run service (serves /wiki). Same image as the public service."
  type        = string
}

variable "container_image" {
  description = "Container image used ONLY to seed the first create. After that the App Layer (gcloud / Cloud Build) owns the running image and terraform ignores changes to it (lifecycle ignore_changes in cloudrun.tf). Defaults to GCP's hello image so the service stands up before the App Layer exists."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 8080
}

variable "cpu_limit" {
  description = "Per-instance CPU limit."
  type        = string
  default     = "1"
}

variable "memory_limit" {
  description = "Per-instance memory limit."
  type        = string
  default     = "512Mi"
}

variable "min_instances" {
  description = "Minimum number of service instances (0 = scale to zero)."
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum number of service instances."
  type        = number
  default     = 4
}

variable "ingress" {
  description = "Ingress restriction. INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER means only the external HTTPS LB (and internal traffic) can reach the service — the public can't hit the run.app URL directly."
  type        = string
  default     = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
}

variable "vpc_egress" {
  description = "VPC egress for Direct VPC egress. PRIVATE_RANGES_ONLY routes only RFC1918 traffic (e.g. Cloud SQL private IP) through the VPC; public egress goes direct."
  type        = string
  default     = "PRIVATE_RANGES_ONLY"
}

variable "deletion_protection" {
  description = "Terraform deletion protection on the Cloud Run service. Off in dev — the service is stateless and recreatable."
  type        = bool
  default     = false
}

variable "invoker_members" {
  description = "Principals granted run.invoker. With ingress locked to the LB and IAP enforcing identity at the front door, allUsers is the standard setting (only the LB can actually reach the service). Tighten if org policy forbids allUsers."
  type        = list(string)
  default     = ["allUsers"]
}

# --- Database wiring (values come from the cloudsql state) ----------------------------------------------------------

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
  description = "Secret Manager secret ID holding the DB password (created by the cloudsql state)."
  type        = string
}

variable "labels" {
  description = "Resource labels (e.g. env, app)."
  type        = map(string)
  default     = {}
}
