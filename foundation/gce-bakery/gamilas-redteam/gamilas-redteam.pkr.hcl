# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer — GCE Bakery — recipe: gamilas-redteam
# Bakes ONE image, two ways: a GCP image (googlecompute) and a DigitalOcean snapshot
# (digitalocean), from the SAME Ubuntu 22.04 base and the SAME provisioner scripts, so
# the attacker box is byte-for-byte identical on both clouds. The image is a red-team
# webapp + GCP-attack toolkit used to run AUTHORIZED security scans against our own
# yamato wiki and prove the GCP defense-in-depth stops, logs, and alerts on every move.
#
# Theme: the attacker is the Gamilas Empire (Star Blazers) laying siege to the Yamato.
# Spoiler — the Wave-Motion-Gun-grade defenses (Cloud Armor, IAP, private Cloud SQL,
# least-privilege SAs, org policies, org-wide log sink) hold. See readme.md for the
# attack -> defense -> "where it's logged" map that drives the presentation.
#
# Why baked, not boot-time installed: the top-level README mandates GCE VMs be baked in
# the bakery to exist on the GCP API, and a pre-baked image means the demo VM boots
# scan-ready in seconds with a frozen, auditable toolset (no apt drift mid-presentation).
#
# Build it:   packer init . && packer validate <vars> . && packer build <vars> .
# Vars live in variables.pkr.hcl; pass secrets via -var or PKR_VAR_* env, never commit.
# ---------------------------------------------------------------------------------------------------------------------

packer {
  required_version = ">= 1.7.0"
  required_plugins {
    googlecompute = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/googlecompute"
    }
    digitalocean = {
      version = ">= 1.2.0"
      source  = "github.com/digitalocean/digitalocean"
    }
  }
}

# A single timestamped name shared by the GCP image and the DO snapshot so the two
# artifacts of one build are easy to correlate in an audit. GCP image names must be
# lowercase, start with a letter, and be <= 63 chars — this fits.
locals {
  image_name = "iq9-img-gamilas-redteam-${formatdate("YYYYMMDD-hhmmss", timestamp())}"

  # Applied to BOTH clouds. "purpose" is deliberately explicit: anyone who finds this
  # box in an audit should immediately know it is a sanctioned testing asset, not a real
  # intrusion. The org log sink will capture its API calls regardless.
  common_labels = {
    layer   = "foundation"
    bakery  = "gamilas-redteam"
    role    = "redteam-scanner"
    purpose = "authorized-security-testing"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Source — GCP image (googlecompute)
# ---------------------------------------------------------------------------------------------------------------------
#
# Builds a private GCE image in the bakery project. NOTE on OS Login: this org enforces
# the compute.requireOsLogin policy. Packer's default temporary-SSH-key flow collides
# with enforced OS Login, so set gcp_use_os_login=true (and run as a principal with
# roles/compute.osAdminLogin + iam.serviceAccountUser) OR bake in a project where the
# policy is relaxed for the bakery. Both paths are documented in readme.md.
source "googlecompute" "gamilas" {
  project_id   = var.gcp_project_id
  zone         = var.gcp_zone
  machine_type = var.gcp_machine_type
  disk_size    = var.disk_size_gb
  disk_type    = "pd-ssd"

  # No `default` network exists in a locked-down Foundation project — name the VPC/subnet
  # explicitly (subnet must be in the zone's region). Defaults to the dedicated bakery VPC.
  network    = var.gcp_network
  subnetwork = var.gcp_subnetwork

  # Network tag the build VM so the IAP-SSH firewall rule (target tag bakery-build) applies.
  tags = var.gcp_network_tags

  # Egress mode (see variables.pkr.hcl). Bakery default: NO public IP — SSH over an IAP
  # tunnel, egress via the bakery Cloud NAT. Flip both off only for an external-IP fallback.
  omit_external_ip = var.gcp_omit_external_ip
  use_internal_ip  = var.gcp_omit_external_ip
  use_iap          = var.gcp_use_iap

  source_image_family = var.gcp_source_image_family
  image_name          = local.image_name
  image_family        = "iq9-redteam"
  image_description   = "Gamilas red-team webapp+GCP scanning toolkit on Ubuntu 22.04 — authorized security testing"

  ssh_username = var.ssh_username
  use_os_login = var.gcp_use_os_login

  labels = local.common_labels
}

# ---------------------------------------------------------------------------------------------------------------------
# Source — DigitalOcean snapshot (digitalocean)
# ---------------------------------------------------------------------------------------------------------------------
#
# Builds a DO snapshot from the same base. DO droplets log in as root, so ssh_username is
# fixed to root here regardless of the GCP setting. The snapshot lands in your DO account
# ready to spin up as a droplet "outside" GCP — the classic external-attacker vantage.
source "digitalocean" "gamilas" {
  api_token = var.do_api_token

  image  = var.do_base_image
  region = var.do_region
  size   = var.do_size

  ssh_username  = "root"
  snapshot_name = local.image_name
  tags          = ["iq9-redteam", "authorized-security-testing"]
}

# ---------------------------------------------------------------------------------------------------------------------
# Build — same scripts onto both sources
# ---------------------------------------------------------------------------------------------------------------------
#
# Provisioner order is intentional: base hardening/runtime first, then the tool tiers
# (recon -> web -> cloud -> creds/wordlists), then we stage the attack-profile runners
# onto the image at /opt/gamilas, then cleanup last so caches/keys never bake in.
build {
  name = "gamilas-redteam"
  sources = [
    "source.googlecompute.gamilas",
    "source.digitalocean.gamilas",
  ]

  # Install the toolkit. sudo for apt/system installs; DEBIAN_FRONTEND keeps apt silent.
  provisioner "shell" {
    execute_command   = "chmod +x {{ .Path }}; sudo -E env {{ .Vars }} {{ .Path }}"
    expect_disconnect = true
    environment_vars  = ["DEBIAN_FRONTEND=noninteractive"]
    scripts = [
      "scripts/00-base.sh",
      "scripts/10-recon-tools.sh",
      "scripts/20-web-tools.sh",
      "scripts/30-cloud-tools.sh",
      "scripts/40-cred-wordlists.sh",
    ]
  }

  # Stage the two attack profiles onto the image so the booted VM is scan-ready.
  provisioner "file" {
    source      = "profiles"
    destination = "/tmp/profiles"
  }
  provisioner "shell" {
    inline = [
      "sudo mkdir -p /opt/gamilas",
      "sudo cp -r /tmp/profiles /opt/gamilas/profiles",
      "sudo chmod -R +x /opt/gamilas/profiles",
      "sudo rm -rf /tmp/profiles",
    ]
  }

  # Cleanup runs last: zero apt caches, shell history, and any cloud-init seed so nothing
  # sensitive bakes into the published image.
  provisioner "shell" {
    execute_command  = "chmod +x {{ .Path }}; sudo -E env {{ .Vars }} {{ .Path }}"
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    scripts          = ["scripts/99-cleanup.sh"]
  }

  # Record what got built where — handy for the audit trail and for grabbing the image
  # IDs to feed Terraform / doctl when you deploy the demo VMs.
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
