# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — module: frontdoor
# A global external Application Load Balancer that fronts the yamato Cloud Run
# service, with Identity-Aware Proxy (IAP) gating the wiki and a public, ungated
# landing page.
#
# Two backend services point at the SAME Cloud Run service, each via its OWN
# serverless NEG (they must not share one — IAP would leak across a shared NEG):
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

  # OWASP preconfigured WAF rule set (Cloud Armor). Each becomes a deny(403) rule.
  # These are exactly the payload families the gamilas-redteam suite throws:
  # sqlmap -> sqli, dalfox -> xss, nikto/nuclei -> scannerdetection, etc.
  waf_rules = [
    { expr = "sqli-v33-stable", priority = 1000, desc = "Block SQL injection (sqlmap)" },
    { expr = "xss-v33-stable", priority = 1001, desc = "Block cross-site scripting (dalfox)" },
    { expr = "lfi-v33-stable", priority = 1002, desc = "Block local file inclusion" },
    { expr = "rfi-v33-stable", priority = 1003, desc = "Block remote file inclusion" },
    { expr = "rce-v33-stable", priority = 1004, desc = "Block remote code execution" },
    { expr = "scannerdetection-v33-stable", priority = 1005, desc = "Block scanners (nikto/nuclei/whatweb)" },
    { expr = "protocolattack-v33-stable", priority = 1006, desc = "Block protocol attacks" },
    { expr = "sessionfixation-v33-stable", priority = 1007, desc = "Block session fixation" },
  ]
}

# --- Cloud Armor edge security policy ------------------------------------------------------------------------------
#
# The marquee defense for the attack demo: OWASP preconfigured WAF rules block injection /
# scan payloads BY NAME, a per-IP rate-based ban throttles then bans the scan flood, and
# Adaptive Protection watches for L7 DDoS. log_level=VERBOSE so each blocked request carries
# the matched WAF rule ID — the evidence the dashboard + presentation feed on. Attached to
# both backends below. Preview vs enforce is var.cloud_armor_preview (default: ENFORCE).
resource "google_compute_security_policy" "edge" {
  count       = var.enable_cloud_armor ? 1 : 0
  project     = var.project_id
  name        = "${local.np}-armor"
  description = "Cloud Armor edge: OWASP WAF + per-IP rate limiting + adaptive protection for the yamato front door."
  type        = "CLOUD_ARMOR"

  # Adaptive Protection (L7 DDoS ML). Toggleable: some projects need Cloud Armor Enterprise
  # for this, so it's gated to keep the apply clean where that's not enrolled.
  dynamic "adaptive_protection_config" {
    for_each = var.enable_adaptive_protection ? [1] : []
    content {
      layer_7_ddos_defense_config {
        enable = true
      }
    }
  }

  # VERBOSE so blocked-request logs include the matched preconfigured WAF rule IDs.
  advanced_options_config {
    log_level = "VERBOSE"
  }

  # Per-source-IP rate limit, then ban — catches the scan flood (ffuf/nuclei/sqlmap volume).
  # CRITICAL ordering: this rule's match is src_ip_ranges=["*"], i.e. EVERY request, and
  # Cloud Armor is first-match-wins by ascending priority. It MUST sit at a HIGHER priority
  # number than the WAF rules (1000-1007) so injection/scan payloads are evaluated and
  # blocked FIRST; otherwise this catch-all short-circuits every request to its conform
  # action (allow) and the WAF rules never run. Hence 2000 (after WAF, before default allow).
  rule {
    action      = "rate_based_ban"
    priority    = 2000
    preview     = var.cloud_armor_preview
    description = "Per-source-IP rate limit; ban offenders (the scan flood)."
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action   = "allow"
      exceed_action    = "deny(429)"
      enforce_on_key   = "IP"
      ban_duration_sec = var.rate_limit_ban_duration_sec
      rate_limit_threshold {
        count        = var.rate_limit_count
        interval_sec = var.rate_limit_interval_sec
      }
    }
  }

  # OWASP preconfigured WAF rules — one deny(403) rule per family.
  dynamic "rule" {
    for_each = local.waf_rules
    content {
      action      = "deny(403)"
      priority    = rule.value.priority
      preview     = var.cloud_armor_preview
      description = rule.value.desc
      match {
        expr {
          expression = "evaluatePreconfiguredWaf('${rule.value.expr}', {'sensitivity': ${var.waf_sensitivity}})"
        }
      }
    }
  }

  # Default allow (required, lowest priority). Legit @iq9.io traffic still meets IAP downstream.
  rule {
    action      = "allow"
    priority    = 2147483647
    description = "Default allow."
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}

# The iap.googleapis.com API is enabled by the foundation project state,
# foundation/gcp-projects/yamato/dev/ — not here.

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
# ONE serverless NEG PER backend service, both pointing at the SAME Cloud Run
# service. They must NOT share a single NEG: IAP enabled on the wiki backend's NEG
# leaks onto a shared NEG and intermittently 403s the public landing. Separate NEGs
# keep IAP enforcement scoped to the wiki backend only.
resource "google_compute_region_network_endpoint_group" "public" {
  project               = var.project_id
  name                  = "${local.np}-neg-public"
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = var.cloud_run_service_name
  }
}

resource "google_compute_region_network_endpoint_group" "wiki" {
  project               = var.project_id
  name                  = "${local.np}-wiki-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = var.wiki_service_name
  }

  # Renamed from "-neg-wiki" + create_before_destroy so that pointing this NEG at
  # the new wiki service replaces it CLEANLY: the new NEG is created and be-wiki
  # repointed before the old NEG is destroyed — avoids the
  # "resourceInUseByAnotherResource" deadlock when a backend still references it.
  lifecycle {
    create_before_destroy = true
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

  # Cloud Armor on the public backend — the unauth scan (Profile 1) hits this first.
  security_policy = var.enable_cloud_armor ? google_compute_security_policy.edge[0].id : null

  backend {
    group = google_compute_region_network_endpoint_group.public.id
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

resource "google_compute_backend_service" "wiki" {
  project               = var.project_id
  name                  = "${local.np}-be-wiki"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  # Cloud Armor on the wiki backend too — defense-in-depth in FRONT of IAP, so injection /
  # scan payloads are blocked at the edge before they even reach the IAP login.
  security_policy = var.enable_cloud_armor ? google_compute_security_policy.edge[0].id : null

  backend {
    group = google_compute_region_network_endpoint_group.wiki.id
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }

  # Google-managed OAuth client (no brand/client resources needed).
  # NOTE: set enabled explicitly — REMOVING the iap block does NOT disable IAP in
  # GCP (terraform just stops managing it), so we toggle via enabled=var.iap_enabled.
  iap {
    enabled = var.iap_enabled
  }
}

# Who may pass IAP on the wiki backend. domain:iq9.io = the whole Workspace org.
resource "google_iap_web_backend_service_iam_member" "wiki" {
  for_each = var.iap_enabled ? toset(var.iap_members) : toset([])

  project             = var.project_id
  web_backend_service = google_compute_backend_service.wiki.name
  role                = "roles/iap.httpsResourceAccessor"
  member              = each.value
}

# --- IAP -> Cloud Run service-agent provisioning --------------------------------------------------------------------

# IAP fronting Cloud Run invokes the backend service on the authenticated user's
# behalf using a project-scoped Google-managed service agent:
#     service-<PROJECT_NUMBER>@gcp-sa-iap.iam.gserviceaccount.com
# That agent must (a) exist in the project, and (b) hold roles/run.invoker on the
# wiki Cloud Run service. Without it, login surfaces the cryptic
# "IAP service account is not provisioned" error from the IAP runtime, regardless
# of the allUsers invoker binding the cloudrun state grants for the LB itself.
# See https://cloud.google.com/iap/docs/enabling-cloud-run.
#
# google_project_service_identity is a google-beta resource — it triggers the
# same creation that `gcloud beta services identity create --service=iap…` does.
# Its destroy is a no-op (Google doesn't permit deletion of managed service
# agents), so we leave it ungated by var.iap_enabled: toggling IAP off should
# not churn the agent, only the IAM binding that uses it.
resource "google_project_service_identity" "iap" {
  provider = google-beta
  project  = var.project_id
  service  = "iap.googleapis.com"
}

# Grant the IAP service agent invoker on the wiki Cloud Run service only —
# scoped to the IAP-gated surface, never the public service. The count-style
# gate matches the iap_members binding above so flipping var.iap_enabled
# cleanly attaches/detaches both.
resource "google_cloud_run_v2_service_iam_member" "iap_invoker_wiki" {
  count = var.iap_enabled ? 1 : 0

  project  = var.project_id
  location = var.region
  name     = var.wiki_service_name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_project_service_identity.iap.email}"
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

    # The internal NOC page rides the SAME IAP-gated backend, so /noc is private to the IAP
    # members (no new service or backend needed). The app serves it from its /noc handler.
    path_rule {
      paths   = [var.noc_path_prefix, "${var.noc_path_prefix}/*"]
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
