# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer — GCE Bakery — recipe: tf-runner
# Bakes the dedicated Terraform RUNNER image — the box that executes every terraform run
# off humans' laptops and inside GCP, so the IaC pipeline has one reproducible, auditable
# execution environment. This is the "iq9-tf-runner" VM referenced in the repo-root
# gcp_provider.tf auth model: identity comes from the ATTACHED service account via the
# metadata server (ADC), never from a key on disk (org policy forbids SA keys anyway).
#
# The swappable-identity idea (Chris's design): the runner operates as a READ-ONLY SA for
# `plan` and a READ-WRITE SA for `apply`, swapped according to the release schedule. The
# IMAGE stays identity-agnostic — it bakes the tools + the tf-run wrapper that selects the
# phase-appropriate SA at runtime. The actual RO/RW SAs and their IAM live in Foundation
# Terraform (see readme.md), so the image is generic and reusable across environments.
#
# Built in the SAME dedicated bakery network as every other recipe
# (foundation/networks/bakery/): no public IP, SSH in over IAP, egress via Cloud NAT.
#
# Build it:  packer init . && packer validate -var gcp_project_id=... . && packer build -var gcp_project_id=... .
# ---------------------------------------------------------------------------------------------------------------------

packer {
  required_version = ">= 1.7.0"
  required_plugins {
    googlecompute = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

locals {
  image_name = "iq9-img-tf-runner-${formatdate("YYYYMMDD-hhmmss", timestamp())}"

  common_labels = {
    layer   = "foundation"
    bakery  = "tf-runner"
    role    = "terraform-runner"
    purpose = "iac-execution"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Source — GCP image (googlecompute). GCP-only by design: the runner's whole job is to
# drive the GCP API as an attached/impersonated SA, so there is no DigitalOcean variant.
# ---------------------------------------------------------------------------------------------------------------------
#
# OS Login note (same as the other recipes): under the enforced compute.requireOsLogin org
# policy keep gcp_use_os_login=true and build as a principal with osAdminLogin +
# serviceAccountUser. Build connectivity is the bakery network: no external IP, IAP tunnel
# for SSH, Cloud NAT for egress.
source "googlecompute" "tf_runner" {
  project_id   = var.gcp_project_id
  zone         = var.gcp_zone
  machine_type = var.gcp_machine_type
  disk_size    = var.disk_size_gb
  disk_type    = "pd-ssd"

  source_image_family = var.gcp_source_image_family
  image_name          = local.image_name
  image_family        = "iq9-tf-runner"
  image_description   = "Dedicated Terraform runner (Ubuntu 22.04): terraform ${var.terraform_version}, gcloud, RO/RW SA-swap wrapper."

  ssh_username = var.ssh_username
  use_os_login = var.gcp_use_os_login

  # Same dedicated bakery network as every recipe (foundation/networks/bakery/).
  network    = var.gcp_network
  subnetwork = var.gcp_subnetwork
  tags       = var.gcp_network_tags

  omit_external_ip = var.gcp_omit_external_ip
  use_internal_ip  = var.gcp_omit_external_ip
  use_iap          = var.gcp_use_iap

  labels = local.common_labels
}

# ---------------------------------------------------------------------------------------------------------------------
# Build — install the toolchain, stage the runner wrapper, then clean up.
# ---------------------------------------------------------------------------------------------------------------------
build {
  name    = "tf-runner"
  sources = ["source.googlecompute.tf_runner"]

  provisioner "shell" {
    execute_command   = "chmod +x {{ .Path }}; sudo -E env {{ .Vars }} {{ .Path }}"
    expect_disconnect = true
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
      "TERRAFORM_VERSION=${var.terraform_version}",
    ]
    scripts = [
      "scripts/00-base.sh",
      "scripts/10-terraform.sh",
      "scripts/20-gcloud.sh",
    ]
  }

  # Stage the RO/RW swap wrapper onto the image at /opt/tf-runner.
  provisioner "file" {
    source      = "runner"
    destination = "/tmp/runner"
  }
  provisioner "shell" {
    inline = [
      "sudo mkdir -p /opt/tf-runner",
      "sudo cp -r /tmp/runner/* /opt/tf-runner/",
      "sudo chmod -R +x /opt/tf-runner",
      "sudo ln -sf /opt/tf-runner/tf-run.sh /usr/local/bin/tf-run",
      "sudo rm -rf /tmp/runner",
    ]
  }

  provisioner "shell" {
    execute_command  = "chmod +x {{ .Path }}; sudo -E env {{ .Vars }} {{ .Path }}"
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    scripts          = ["scripts/99-cleanup.sh"]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
