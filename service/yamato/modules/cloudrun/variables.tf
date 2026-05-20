# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — module: cloudrun — inputs
# ---------------------------------------------------------------------------------------------------------------------

variable "project_id" {
  description = "Project that owns the Cloud Run service and connector."
  type        = string
}

variable "region" {
  description = "Region for the service and the Serverless VPC Access connector."
  type        = string
}

# --- Serverless VPC Access connector -------------------------------------------------------------------------------

variable "network_name" {
  description = "Name of the app VPC the connector attaches to (e.g. iq9-vpc-dev-yamato)."
  type        = string
}

variable "connector_name" {
  description = "Serverless VPC Access connector name. Max 25 chars."
  type        = string
}

variable "connector_cidr" {
  description = "Unused /28 in the VPC for the connector. Reserved by the network state (10.10.16.0/28 in dev)."
  type        = string
}

variable "connector_min_instances" {
  description = "Minimum connector instances."
  type        = number
  default     = 2
}

variable "connector_max_instances" {
  description = "Maximum connector instances."
  type        = number
  default     = 3
}

variable "connector_machine_type" {
  description = "Connector machine type."
  type        = string
  default     = "e2-micro"
}

# --- Runtime identity -----------------------------------------------------------------------------------------------

variable "service_account_id" {
  description = "Account ID (local part) for the Cloud Run runtime service account."
  type        = string
}

# --- The service ----------------------------------------------------------------------------------------------------

variable "service_name" {
  description = "Cloud Run service name."
  type        = string
}

variable "container_image" {
  description = "Container image to run. Defaults to GCP's hello image so the service stands up before the real app exists; flip to the Artifact Registry image once it's built and pushed."
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
  description = "Connector egress. PRIVATE_RANGES_ONLY routes only RFC1918 traffic (e.g. Cloud SQL private IP) through the VPC; public egress goes direct."
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
