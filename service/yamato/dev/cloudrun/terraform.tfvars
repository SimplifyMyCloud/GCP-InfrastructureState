# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — yamato / dev / cloudrun — dev environment values
# ---------------------------------------------------------------------------------------------------------------------
project_id         = "iq9-gcp-dev-yamato"
region             = "us-west1"
network_name       = "iq9-vpc-dev-yamato"
subnet_name        = "iq9-subnet-dev-yamato"
service_name       = "iq9-run-dev-yamato"
service_account_id = "iq9-yamato-dev-run"

# Placeholder image so the service stands up before the App Layer exists.
# After the first app build+push, flip this to:
#   us-west1-docker.pkg.dev/iq9-gcp-dev-yamato/yamato/yamato:<tag>
container_image = "us-docker.pkg.dev/cloudrun/container/hello"

# DB wiring — matches the cloudsql state. connection_name is deterministic:
#   <project>:<region>:<instance_name>
db_connection_name = "iq9-gcp-dev-yamato:us-west1:yamato-dev"
db_name            = "yamato"
db_user            = "yamato_app"
password_secret_id = "yamato-dev-db-password"
