# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — yamato / dev / frontdoor — dev environment values
# ---------------------------------------------------------------------------------------------------------------------
project_id             = "iq9-gcp-dev-yamato"
region                 = "us-west1"
name_prefix            = "iq9-dev-yamato"
domain                 = "yamato-dev.iq9.io"
cloud_run_service_name = "iq9-run-dev-yamato"
wiki_service_name      = "iq9-run-dev-yamato-wiki"

# Who may pass IAP on /wiki: both Cloud Identity domains. simplifymy.cloud is the
# org's primary domain (where chris@ lives); iq9.io is the secondary domain.
# IAP uses the Google-managed OAuth client; no brand/client or support email needed.
iap_members = ["domain:iq9.io", "domain:simplifymy.cloud"]

# IAP gates /wiki only. Now safe to keep on: /wiki routes to its OWN Cloud Run
# service (iq9-run-dev-yamato-wiki), so IAP no longer leaks onto the public path.
iap_enabled = true

# Cloud Armor edge defense: OWASP WAF + per-IP rate-limit ban + adaptive protection on
# both backends. ENFORCE mode (preview=false) so the gamilas attack is actively blocked
# and every block logged with the matched rule — the demo's marquee defense.
enable_cloud_armor  = true
cloud_armor_preview = false

# Adaptive Protection (L7 DDoS ML). If `terraform apply` errors that this needs Cloud
# Armor Enterprise, set this to false — the WAF + rate-limit rules work without it.
enable_adaptive_protection = true
