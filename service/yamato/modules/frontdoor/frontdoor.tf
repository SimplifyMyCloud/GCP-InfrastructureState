# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — module: frontdoor
# A global external Application Load Balancer that fronts the yamato Cloud Run
# service, with Identity-Aware Proxy (IAP) gating the wiki and a public, ungated
# landing page.
#
# Two backend services point at the SAME Cloud Run service via one serverless NEG:
#
#   - "public"  no IAP    -> default route (the Star Blazers landing page at "/")
#   - "wiki"    IAP on    -> the wiki path prefix (var.wiki_path_prefix, e.g. /wiki)
#
# The URL map routes var.wiki_path_prefix to the IAP-protected backend and
# everything else to the public backend. IAP is granted to var.iap_members
# (default domain:iq9.io), so only @iq9.io identities can pass the login.
#
# APP CONTRACT: the Cloud Run app must serve public content (landing, theme
# assets) at paths OUTSIDE var.wiki_path_prefix, and ALL protected content under
# var.wiki_path_prefix — IAP only covers that prefix.
#
# DNS: this module does not manage DNS (iq9.io is not in this repo). After apply,
# create an A record  <var.domain> -> <output: load_balancer_ip>  wherever iq9.io
# is hosted. The managed certificate only finishes provisioning once that record
# resolves to the LB IP.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  np = var.name_prefix
}

resource "google_project_service" "iap" {
  project = var.project_id
  service = "iap.googleapis.com"

  disable_on_destroy = false
}

# --- Global external IP + managed certificate ----------------------------------------------------------------------

resource "google_compute_global_address" "this" {
  project = var.project_id
  name    = "${local.np}-ip"
}

resource "google_compute_managed_ssl_certificate" "this" {
  project = var.project_id
  name    = "${local.np}-cert"

  managed {
    domains = [var.domain]
  }
}

# --- Serverless NEG -> the Cloud Run service -----------------------------------------------------------------------
#
# One NEG, referenced by both backend services below.
resource "google_compute_region_network_endpoint_group" "this" {
  project               = var.project_id
  name                  = "${local.np}-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = var.cloud_run_service_name
  }
}

# --- IAP OAuth ------------------------------------------------------------------------------------------------------
#
# No google_iap_brand / google_iap_client here on purpose: those rely on the IAP
# OAuth Admin API, deprecated after July 2025. Instead the wiki backend below
# enables IAP with the Google-managed OAuth client (`iap { enabled = true }` with
# no client id/secret) — Google provisions and manages the OAuth consent and
# credential automatically for the org.

# --- Backend services ----------------------------------------------------------------------------------------------
#
# EXTERNAL_MANAGED = global external Application LB. Serverless backends use no
# health checks.
resource "google_compute_backend_service" "public" {
  project               = var.project_id
  name                  = "${local.np}-be-public"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.this.id
  }
}

resource "google_compute_backend_service" "wiki" {
  project               = var.project_id
  name                  = "${local.np}-be-wiki"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.this.id
  }

  # Google-managed OAuth client (no brand/client resources needed).
  iap {
    enabled = true
  }

  depends_on = [google_project_service.iap]
}

# Who may pass IAP on the wiki backend. domain:iq9.io = the whole Workspace org.
resource "google_iap_web_backend_service_iam_member" "wiki" {
  for_each = toset(var.iap_members)

  project             = var.project_id
  web_backend_service = google_compute_backend_service.wiki.name
  role                = "roles/iap.httpsResourceAccessor"
  member              = each.value
}

# --- URL map: public by default, IAP for the wiki path -------------------------------------------------------------

resource "google_compute_url_map" "this" {
  project         = var.project_id
  name            = "${local.np}-urlmap"
  default_service = google_compute_backend_service.public.id

  host_rule {
    hosts        = [var.domain]
    path_matcher = "main"
  }

  path_matcher {
    name            = "main"
    default_service = google_compute_backend_service.public.id

    path_rule {
      paths   = [var.wiki_path_prefix, "${var.wiki_path_prefix}/*"]
      service = google_compute_backend_service.wiki.id
    }
  }
}

# --- HTTPS front end -----------------------------------------------------------------------------------------------

resource "google_compute_target_https_proxy" "this" {
  project          = var.project_id
  name             = "${local.np}-https"
  url_map          = google_compute_url_map.this.id
  ssl_certificates = [google_compute_managed_ssl_certificate.this.id]
}

resource "google_compute_global_forwarding_rule" "https" {
  project               = var.project_id
  name                  = "${local.np}-fr-https"
  target                = google_compute_target_https_proxy.this.id
  ip_address            = google_compute_global_address.this.address
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

# --- Optional HTTP -> HTTPS redirect -------------------------------------------------------------------------------

resource "google_compute_url_map" "redirect" {
  count = var.enable_http_redirect ? 1 : 0

  project = var.project_id
  name    = "${local.np}-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "redirect" {
  count = var.enable_http_redirect ? 1 : 0

  project = var.project_id
  name    = "${local.np}-http"
  url_map = google_compute_url_map.redirect[0].id
}

resource "google_compute_global_forwarding_rule" "http" {
  count = var.enable_http_redirect ? 1 : 0

  project               = var.project_id
  name                  = "${local.np}-fr-http"
  target                = google_compute_target_http_proxy.redirect[0].id
  ip_address            = google_compute_global_address.this.address
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}
