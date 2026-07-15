# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Networks — yamato / dev
# ---------------------------------------------------------------------------------------------------------------------
#
# A single, deliberately small VPC inside iq9-gcp-dev-yamato. One project,
# one VPC — no Shared VPC, no host/service split. Dev is meant to empower
# fast iteration; the multi-project networking model that prod will use
# would add daily friction (cross-project IAM, host-project quotas, two
# states to apply per change) for zero developer-velocity benefit at this
# scale.
#
# Region: us-west1 (Oregon, The Dalles). Matches the bootstrap region and
# the provider default in ../../../../gcp_provider.tf, so the runner VM,
# the state bucket, this VPC, and any service-layer compute all live on
# the same continental side of the planet.
#
# What this state owns (APIs are enabled by foundation/gcp-projects/yamato/dev/):
#
#   1. iq9-vpc-dev-yamato               the VPC itself, custom-mode
#   2. iq9-subnet-dev-yamato            the only subnet, /20 in us-west1
#   3. iq9-psa-dev-yamato               PSA range reservation
#   4. PSA peering connection           VPC <-> servicenetworking producers
#
# What this state does NOT own (deferred to the Service Layer):
#
#   - Serverless VPC Access connector  (created when Cloud Run lands)
#   - Cloud NAT / Cloud Router         (not needed — Cloud Run egresses
#                                       direct-to-internet for public
#                                       traffic; only private RFC1918
#                                       targets route via VPC)
#   - Firewall rules                   (not needed — no GCE VMs, and the
#                                       implicit allow-egress + stateful
#                                       firewall handle Cloud Run -> SQL
#                                       return traffic)
#   - Cloud SQL, Cloud Run, GKE, etc.  (Service Layer concerns)
#
# CIDR plan inside the VPC (10.0.0.0/8 RFC1918 space):
#
#   10.10.0.0/20   subnet for primary workloads        (4096 addresses)
#   10.10.16.0/28  Serverless VPC Access connector      (16 addresses, reserved by service layer when CR lands)
#   10.20.0.0/20   PSA range for service producers      (4096 addresses, peered to Cloud SQL et al)
#
# These three ranges don't overlap, leaving plenty of room for future
# subnets (GKE secondary ranges, additional connectors, internal LB
# proxy-only subnets, etc.) without renumbering.
# ---------------------------------------------------------------------------------------------------------------------


# ---------------------------------------------------------------------------------------------------------------------
# APIs — enabled by FOUNDATION (the project state), not here.
# ---------------------------------------------------------------------------------------------------------------------
#
# compute.googleapis.com and servicenetworking.googleapis.com (and every other API
# this project uses) are enabled by foundation/gcp-projects/yamato/dev/. API
# enablement is a foundation-layer responsibility; this state assumes they are
# already on, so apply the gcp-projects state before this one.


# ---------------------------------------------------------------------------------------------------------------------
# 3. The VPC itself.
# ---------------------------------------------------------------------------------------------------------------------
#
# Custom mode (auto_create_subnetworks = false) so we explicitly declare
# every subnet. Auto mode would silently create a /20 in every GCP region,
# which is a sprawling attack surface and a CIDR-planning nightmare.
#
# routing_mode = "REGIONAL" because all yamato/dev workloads live in a
# single region (us-west1). REGIONAL mode means dynamic routes from Cloud
# Routers in this region don't get advertised to other regions — there
# aren't any, so this is mostly hygiene. If we later add a second region
# we'd flip to "GLOBAL" and re-evaluate.
#
# delete_default_routes_on_create = false. The default 0.0.0.0/0 route
# pointing to the default-internet-gateway is what lets Cloud Run egress
# (when routing through the VPC) actually reach the internet. Removing it
# would require explicit replacement routes via Cloud NAT, which we're
# deliberately not provisioning here.
#
# Requires compute.googleapis.com — enabled by the gcp-projects foundation state,
# which must be applied before this one.

resource "google_compute_network" "yamato_dev" {
  project = "iq9-gcp-dev-yamato"
  name    = "iq9-vpc-dev-yamato"

  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = false

  description = "Per-project VPC for yamato dev. Single subnet, single region (us-west1)."
}


# ---------------------------------------------------------------------------------------------------------------------
# 4. The (only) subnet.
# ---------------------------------------------------------------------------------------------------------------------
#
# 10.10.0.0/20 = 4096 addresses, plenty for a dev environment. Lives in
# us-west1 (Oregon).
#
# private_ip_google_access = true so resources WITHOUT external IPs can
# still reach Google APIs (Cloud SQL admin endpoints, Cloud Storage,
# Logging, etc.) over Google's internal network rather than via NAT.
# Critical for the Cloud Run + Cloud SQL combo we're building toward —
# Cloud Run on a VPC connector gets no external IP, and we want it to
# talk to Google APIs without paying a NAT toll.
#
# Flow logs and VPC Flow Logs Aggregation: omitted intentionally. Dev
# doesn't need per-flow telemetry; the cost (~$0.50/GB) and the noise
# of all the implicit Google API chatter outweigh the visibility benefit.
# Prod will turn this on with sampling.

resource "google_compute_subnetwork" "yamato_dev" {
  project = "iq9-gcp-dev-yamato"
  name    = "iq9-subnet-dev-yamato"

  network       = google_compute_network.yamato_dev.id
  region        = "us-west1"
  ip_cidr_range = "10.10.0.0/20"

  private_ip_google_access = true

  description = "Primary subnet for yamato dev workloads in us-west1 (Oregon)."
}


# ---------------------------------------------------------------------------------------------------------------------
# 5. PSA range — reserves IP space for Service Networking peering.
# ---------------------------------------------------------------------------------------------------------------------
#
# Private Service Access (PSA) is the mechanism that lets managed Google
# services (Cloud SQL with private IP, Memorystore, Filestore, AlloyDB,
# ...) attach to a customer VPC over a peering. The peering needs an IP
# range carved out of the customer's address space; that's what this
# resource declares.
#
# 10.20.0.0/20 = 4096 addresses, deliberately disjoint from the subnet
# range above (10.10.0.0/20). Cloud SQL needs at least a /24 inside the
# peered range; a /20 leaves headroom for additional service producers
# without re-reserving.
#
# purpose = "VPC_PEERING" tells GCP this address is for service producer
# peering specifically (vs. private services, internal LBs, etc.).
#
# This resource only RESERVES the range. The actual peering connection
# is established by google_service_networking_connection below.

resource "google_compute_global_address" "psa_range" {
  project = "iq9-gcp-dev-yamato"
  name    = "iq9-psa-dev-yamato"

  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  ip_version    = "IPV4"
  prefix_length = 20
  address       = "10.20.0.0"
  network       = google_compute_network.yamato_dev.id

  description = "PSA range for service producer peering (Cloud SQL, Memorystore, etc.) on iq9-vpc-dev-yamato."
}


# ---------------------------------------------------------------------------------------------------------------------
# 6. Establish the peering with the Service Networking API.
# ---------------------------------------------------------------------------------------------------------------------
#
# This resource is the actual VPC peering. Once it exists, any service
# producer that asks GCP for a private endpoint inside iq9-vpc-dev-yamato
# (e.g. Cloud SQL with private IP) gets an address from the PSA range
# above and can be reached from within the VPC.
#
# A given VPC can hold ONE peering connection per service producer
# endpoint (servicenetworking.googleapis.com). Multiple consumer
# resources (Cloud SQL + Memorystore + ...) all share the same peering.
# So this is a one-time setup — set it up here in foundation, and every
# Service Layer state that wants a private endpoint just consumes it.
#
# deletion_policy = "ABANDON" because tearing down this peering would
# strand any service producer instances using it (Cloud SQL with private
# IP would lose connectivity). If the connection ever truly needs to go
# away, it's a manual, deliberate operation.

resource "google_service_networking_connection" "psa_peering" {
  network                 = google_compute_network.yamato_dev.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.psa_range.name]

  deletion_policy = "ABANDON"
}
