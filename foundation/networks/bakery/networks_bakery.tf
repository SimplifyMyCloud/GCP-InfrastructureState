# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Networks — bakery
# ---------------------------------------------------------------------------------------------------------------------
#
# A dedicated, deliberately tiny VPC whose ONLY job is to host the ephemeral
# build VMs Packer spins up in the GCE Bakery (foundation/gce-bakery/). Shared by
# every bakery recipe (gamilas-redteam, gitlab-offline, ...). It is intentionally
# separate from any application VPC.
#
# Why its own network? An image-build VM is privileged (it installs software
# as root), internet-pulling, and short-lived — and the bakery is a supply-
# chain chokepoint: poison one baked image and every VM downstream inherits
# it. Isolating the forge keeps a compromise during a bake off the app's wire.
#
# Posture — the bakery practices what the demo preaches:
#
#   * Build VMs get NO external IP. Inbound SSH for Packer arrives over an
#     IAP tunnel (Identity-Aware Proxy), so there is zero public attack
#     surface on the box.
#   * Outbound egress (apt / go / git / pip to install the toolkit) leaves
#     through a Cloud NAT — one controlled, logged egress IP.
#
# Home project: iq9-gcp-dev-yamato (where the bakery lives for now). The
# eventual home is a dedicated ops/bakery project (e.g. iq9-gcp-ops-01); when
# it exists, change the project string on these resources and the Packer
# gcp_project_id var. Nothing else moves.
#
# Region: us-west1 (Oregon) — we do everything in us-west1. The baked IMAGE is
# global once created, so region only governs where the throwaway build VM runs.
#
# What this state owns:
#
#   1. iq9-vpc-bakery-us-we1                 the VPC, custom-mode
#   2. iq9-subnet-bakery-build               the build subnet, /24 in us-west1
#   3. iq9-rtr-bakery-us-we1                 Cloud Router (carries the NAT)
#   4. iq9-nat-bakery-us-we1                 Cloud NAT (build VM egress)
#   5. iq9-fw-bakery-ssh-iap-build-...       IAP-range -> tcp:22 firewall rule
#
# CIDR: 10.50.0.0/24 (256 addrs) — disjoint from the yamato VPC (10.10/10.20)
# so the two could be peered later without renumbering. /24 is ample for the
# one ephemeral build VM that exists at a time.
# ---------------------------------------------------------------------------------------------------------------------


# ---------------------------------------------------------------------------------------------------------------------
# APIs — enabled by FOUNDATION (the project state), not here.
# ---------------------------------------------------------------------------------------------------------------------
#
# compute.googleapis.com (and IAP) are enabled by foundation/gcp-projects/yamato/dev/.
# This state assumes they are already on.


# ---------------------------------------------------------------------------------------------------------------------
# 1. The bakery VPC.
# ---------------------------------------------------------------------------------------------------------------------
#
# Custom mode so the only subnet is the one we declare — no auto /20 in every
# region. REGIONAL routing because the bakery is single-region. Default routes
# kept (delete_default_routes_on_create = false) so the 0.0.0.0/0 -> internet
# gateway route exists for the Cloud NAT to use.
resource "google_compute_network" "bakery" {
  project = "iq9-gcp-dev-yamato"
  name    = "iq9-vpc-bakery-us-we1"

  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = false

  description = "Dedicated VPC for GCE Bakery build VMs. Isolated from app networks; egress via Cloud NAT, SSH via IAP."
}


# ---------------------------------------------------------------------------------------------------------------------
# 2. The build subnet.
# ---------------------------------------------------------------------------------------------------------------------
#
# private_ip_google_access = true so the no-external-IP build VM can reach
# Google APIs (Artifact Registry, Storage, the GCP apt mirror) over Google's
# network even before NAT; general internet (github/go.dev) still goes via NAT.
resource "google_compute_subnetwork" "bakery_build" {
  project = "iq9-gcp-dev-yamato"
  name    = "iq9-subnet-bakery-build"

  network       = google_compute_network.bakery.id
  region        = "us-west1"
  ip_cidr_range = "10.50.0.0/24"

  private_ip_google_access = true

  description = "Subnet for ephemeral Packer build VMs in us-west1."
}


# ---------------------------------------------------------------------------------------------------------------------
# 3 + 4. Cloud Router + Cloud NAT — outbound egress for the no-public-IP build VM.
# ---------------------------------------------------------------------------------------------------------------------
#
# The build VM has no external IP, so without NAT it could not apt/go/git the
# toolkit. NAT gives it controlled outbound from a single Google-allocated IP
# (AUTO_ONLY). ALL_SUBNETWORKS_ALL_IP_RANGES because this VPC has exactly one
# subnet that exists solely to be NAT'd.
resource "google_compute_router" "bakery" {
  project = "iq9-gcp-dev-yamato"
  name    = "iq9-rtr-bakery-us-we1"
  region  = "us-west1"
  network = google_compute_network.bakery.id

  description = "Cloud Router carrying the bakery Cloud NAT."
}

resource "google_compute_router_nat" "bakery" {
  project = "iq9-gcp-dev-yamato"
  name    = "iq9-nat-bakery-us-we1"
  region  = "us-west1"
  router  = google_compute_router.bakery.name

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# 5. Firewall — IAP range only -> tcp:22 on tagged build VMs.
# ---------------------------------------------------------------------------------------------------------------------
#
# Packer reaches the build VM over an IAP tunnel; IAP forwards from the fixed
# range 35.235.240.0/20. This is the ONLY ingress to the bakery, scoped to
# tcp:22 and to VMs carrying the `bakery-build` network tag (which the Packer
# googlecompute source sets via var.gcp_network_tags). No 0.0.0.0/0, ever.
resource "google_compute_firewall" "bakery_ssh_iap" {
  project = "iq9-gcp-dev-yamato"
  name    = "iq9-fw-bakery-ssh-iap-build-tcp-22-allow"
  network = google_compute_network.bakery.id

  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["bakery-build"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  description = "Allow IAP TCP-forwarding range to SSH (tcp:22) into tagged bakery build VMs."
}
