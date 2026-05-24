# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — yamato / dev / logging — dev environment values
# ---------------------------------------------------------------------------------------------------------------------
project_id         = "iq9-gcp-dev-yamato"
region             = "us-west1"
run_service_name   = "iq9-run-dev-yamato"
sql_instance_name  = "yamato-dev"
notification_email = "chris@simplifymy.cloud"

# Cloud Armor blocks alert: keep false until Cloud Armor has logged its first DENY (the
# metric needs data before Monitoring will accept the alert). After the front-door reorder
# is applied and a real block has happened, flip to true and re-apply this state.
enable_cloud_armor_alert = false
