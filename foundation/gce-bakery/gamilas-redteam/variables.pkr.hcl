# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer — GCE Bakery — recipe: gamilas-redteam — input variables
# Build-time inputs only. Credentials (do_api_token) and project context are variables —
# never hardcoded — so the recipe stays public-safe. Tool SELECTION is hardcoded in the
# provisioner scripts (Foundation convention: the security perimeter is fixed in code,
# not parameterised). Pass secrets via -var '...' or PKR_VAR_do_api_token env at build.
# ---------------------------------------------------------------------------------------------------------------------

# --- Shared ---------------------------------------------------------------------------------------------------------

variable "ssh_username" {
  type        = string
  default     = "packer"
  description = "SSH user Packer uses on the GCP build VM. Ignored when gcp_use_os_login=true (OS Login derives the user). DO always uses root."
}

variable "disk_size_gb" {
  type        = number
  default     = 30
  description = "Boot disk size for the build VM / image. 30G comfortably holds the toolkit + SecLists wordlists + nuclei templates."
}

# --- GCP (googlecompute) --------------------------------------------------------------------------------------------

variable "gcp_project_id" {
  type        = string
  default     = ""
  description = "GCP project that owns the bakery build VM and the resulting private image. e.g. iq9-gcp-ops-01."
}

variable "gcp_zone" {
  type        = string
  default     = "us-west1-a"
  description = "Zone for the throwaway build VM. MUST be in the same region as gcp_subnetwork (us-west1 for the dev-yamato subnet)."
}

# Locked-down Foundation projects have NO `default` VPC, so the build VM must be told
# which network/subnet to use. Defaults point at the DEDICATED BAKERY VPC — isolated from
# the app's serverless network — defined in foundation/networks/bakery/ (apply it first).
variable "gcp_network" {
  type        = string
  default     = "iq9-vpc-bakery-us-we1"
  description = "VPC network for the build VM. The dedicated bakery VPC (no `default` network exists in this org)."
}

variable "gcp_subnetwork" {
  type        = string
  default     = "iq9-subnet-bakery-build"
  description = "Subnet for the build VM. Must live in the gcp_zone's region (us-west1)."
}

variable "gcp_network_tags" {
  type        = list(string)
  default     = ["bakery-build"]
  description = "Network tags on the build VM. Must include the tag targeted by the IAP-SSH firewall rule (bakery-build) so Packer can reach tcp:22 over the tunnel."
}

# Egress mode for the build VM. The bakery VPC has NO external IPs by design — SSH comes in
# over an IAP tunnel and egress (apt/go/git) goes out through the bakery Cloud NAT. This is
# the "no public IPs" posture the demo itself preaches.
# - omit_external_ip=true + use_iap=true (default): no public IP; SSH via IAP; egress via NAT.
# - set both false ONLY to fall back to an ephemeral external IP (needs the org policy to allow it).
variable "gcp_omit_external_ip" {
  type        = bool
  default     = true
  description = "Build the VM with NO external IP (bakery default). Set false only to fall back to an ephemeral external IP where the org policy allows it."
}

variable "gcp_use_iap" {
  type        = bool
  default     = true
  description = "SSH into the build VM through an IAP tunnel instead of a public IP (bakery default). Requires gcloud installed + roles/iap.tunnelResourceAccessor and the IAP-range firewall rule on tcp:22."
}

variable "gcp_machine_type" {
  type        = string
  default     = "e2-standard-2"
  description = "Build VM size. 2 vCPU / 8GB is plenty to compile the Go tools and install the suite."
}

variable "gcp_source_image_family" {
  type        = string
  default     = "ubuntu-2204-lts"
  description = "Base image family to bake from. Ubuntu 22.04 LTS — broad apt + Go tooling support for the red-team suite."
}

variable "gcp_use_os_login" {
  type        = bool
  default     = true
  description = "Use OS Login for the SSH session. Keep true under the enforced compute.requireOsLogin org policy; set false only if the bakery project relaxes that policy."
}

# --- DigitalOcean (digitalocean) ------------------------------------------------------------------------------------

variable "do_api_token" {
  type        = string
  default     = ""
  sensitive   = true
  description = "DigitalOcean API token with write scope. Pass via PKR_VAR_do_api_token — do NOT commit. Leave empty to build the GCP image only (use: packer build -only=gamilas-redteam.googlecompute.gamilas .)."
}

variable "do_base_image" {
  type        = string
  default     = "ubuntu-22-04-x64"
  description = "DO base image slug to bake from — kept on 22.04 to match the GCP base."
}

variable "do_region" {
  type        = string
  default     = "fra1"
  description = "DO region for the build droplet (Frankfurt, near the GCP eu-west3 default)."
}

variable "do_size" {
  type        = string
  default     = "s-2vcpu-4gb"
  description = "DO build droplet size. Snapshots are region-portable, so this only affects build speed/cost."
}
