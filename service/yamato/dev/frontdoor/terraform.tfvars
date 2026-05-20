# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — yamato / dev / frontdoor — dev environment values
# ---------------------------------------------------------------------------------------------------------------------
project_id             = "iq9-gcp-dev-yamato"
region                 = "us-west1"
name_prefix            = "iq9-dev-yamato"
domain                 = "yamato-dev.iq9.io"
cloud_run_service_name = "iq9-run-dev-yamato"

# iap_members defaults to ["domain:iq9.io"] in the module — only @iq9.io may log in.
# IAP uses the Google-managed OAuth client; no brand/client or support email needed.
