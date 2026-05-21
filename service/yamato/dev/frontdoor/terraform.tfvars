# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — yamato / dev / frontdoor — dev environment values
# ---------------------------------------------------------------------------------------------------------------------
project_id             = "iq9-gcp-dev-yamato"
region                 = "us-west1"
name_prefix            = "iq9-dev-yamato"
domain                 = "yamato-dev.iq9.io"
cloud_run_service_name = "iq9-run-dev-yamato"

# Who may pass IAP on /wiki: both Cloud Identity domains. simplifymy.cloud is the
# org's primary domain (where chris@ lives); iq9.io is the secondary domain.
# IAP uses the Google-managed OAuth client; no brand/client or support email needed.
iap_members = ["domain:iq9.io", "domain:simplifymy.cloud"]

# TEMPORARY (debugging): IAP off to isolate whether IAP-on-shared-service is what's
# 403-ing the public path. Set back to true (or remove) once confirmed.
iap_enabled = false
