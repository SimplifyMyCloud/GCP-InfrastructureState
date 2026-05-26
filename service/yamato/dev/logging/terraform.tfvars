# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — yamato / dev / logging — dev environment values
# ---------------------------------------------------------------------------------------------------------------------
project_id         = "iq9-gcp-dev-yamato"
region             = "us-west1"
run_service_name   = "iq9-run-dev-yamato"
sql_instance_name  = "yamato-dev"
notification_email = "chris@simplifymy.cloud"

# Cloud Armor blocks alert: enabled on 2026-05-24 after the first volley seeded the
# `cloud_armor_blocked` log metric — 11 of 14 attacks blocked across rules 1000-1007, so
# the descriptor is now registered with http_load_balancer and the alert validates.
enable_cloud_armor_alert = true
