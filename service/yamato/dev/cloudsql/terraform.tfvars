# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — yamato / dev / cloudsql — dev environment values
# ---------------------------------------------------------------------------------------------------------------------
project_id         = "iq9-gcp-dev-yamato"
region             = "us-west1"
network_id         = "projects/iq9-gcp-dev-yamato/global/networks/iq9-vpc-dev-yamato"
instance_name      = "yamato-dev"
database_name      = "yamato"
db_user            = "yamato_app"
password_secret_id = "yamato-dev-db-password"
