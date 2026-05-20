# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Projects — yamato / dev — API enablement
# ---------------------------------------------------------------------------------------------------------------------
#
# API enablement is a FOUNDATION-layer responsibility. The foundation TF identity
# has permission to enable services; in a hardened split-identity setup the
# Service-layer TF identity deliberately does NOT (it can create resources but not
# turn on APIs). So every API the yamato/dev project needs is enabled HERE, in the
# project's own foundation state, and the Service Layer assumes they're already on.
#
# disable_on_destroy = false: destroying this state's TF resources must never
# disable a live API out from under running workloads. Disabling an API is a
# deliberate, manual operation.
#
# The list is hardcoded (foundation convention) — reading it tells you exactly which
# Google services this project is permitted to use.

resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com",           # VPC, subnet, global addresses, the LB
    "servicenetworking.googleapis.com", # PSA peering for Cloud SQL private IP
    "sqladmin.googleapis.com",          # Cloud SQL
    "secretmanager.googleapis.com",     # DB password secret
    "run.googleapis.com",               # Cloud Run
    "vpcaccess.googleapis.com",         # Serverless VPC Access connector
    "artifactregistry.googleapis.com",  # app image repo
    "cloudbuild.googleapis.com",        # image builds
    "iap.googleapis.com",               # Identity-Aware Proxy on the front door
    "logging.googleapis.com",           # log buckets, sinks, log-based metrics
    "monitoring.googleapis.com",        # dashboards, alert policies
  ])

  project = google_project.yamato_dev.project_id
  service = each.value

  disable_on_destroy = false
}
