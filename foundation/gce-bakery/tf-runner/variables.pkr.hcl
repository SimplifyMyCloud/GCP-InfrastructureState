# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer — GCE Bakery — recipe: tf-runner — input variables
# Build-time inputs only. No secrets here — the runner is keyless (identity is the attached
# or impersonated SA at runtime, never a baked key). Tool versions are pinned for
# reproducible bakes. Network defaults match the dedicated bakery VPC.
# ---------------------------------------------------------------------------------------------------------------------

variable "terraform_version" {
  type        = string
  default     = "1.10.5"
  description = "Exact Terraform version to bake. Keep it satisfying the repo's required_version (~> 1.10) so the runner and the code agree."
}

# --- Shared GCP build inputs ----------------------------------------------------------------------------------------

variable "ssh_username" {
  type        = string
  default     = "packer"
  description = "SSH user Packer uses on the build VM. Ignored when gcp_use_os_login=true."
}

variable "disk_size_gb" {
  type        = number
  default     = 20
  description = "Boot disk size for the build VM / image. 20G is ample for terraform + gcloud + a checked-out IaC repo."
}

variable "gcp_project_id" {
  type        = string
  default     = ""
  description = "GCP project that owns the build VM and the resulting private image (e.g. iq9-gcp-dev-yamato, or the ops project)."
}

variable "gcp_zone" {
  type        = string
  default     = "us-west1-a"
  description = "Zone for the throwaway build VM. MUST be in the same region as gcp_subnetwork (us-west1)."
}

variable "gcp_machine_type" {
  type        = string
  default     = "e2-standard-2"
  description = "Build VM size (build speed only; the DEPLOYED runner's size is a separate deploy-time choice)."
}

variable "gcp_source_image_family" {
  type        = string
  default     = "ubuntu-2204-lts"
  description = "Base image family. Ubuntu 22.04 LTS."
}

variable "gcp_use_os_login" {
  type        = bool
  default     = true
  description = "Use OS Login for the SSH session. Keep true under the enforced compute.requireOsLogin org policy."
}

# --- Bakery network (defaults match foundation/networks/bakery/) -----------------------------------------------------

variable "gcp_network" {
  type        = string
  default     = "iq9-vpc-bakery-us-we1"
  description = "VPC network for the build VM — the dedicated bakery VPC."
}

variable "gcp_subnetwork" {
  type        = string
  default     = "iq9-subnet-bakery-build"
  description = "Subnet for the build VM. Must live in the gcp_zone's region (us-west1)."
}

variable "gcp_network_tags" {
  type        = list(string)
  default     = ["bakery-build"]
  description = "Network tags on the build VM. Must include the tag targeted by the bakery IAP-SSH firewall rule (bakery-build)."
}

variable "gcp_omit_external_ip" {
  type        = bool
  default     = true
  description = "Build the VM with NO external IP (bakery default). Set false only for an external-IP fallback where the org policy allows it."
}

variable "gcp_use_iap" {
  type        = bool
  default     = true
  description = "SSH into the build VM through an IAP tunnel instead of a public IP (bakery default)."
}
