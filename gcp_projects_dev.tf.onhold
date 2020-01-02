# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Projects
# ensures GCP Projects per Infrastructure Environment
# for the Foundation Layer development environment, ensure a random prefix is included to avoid naming collisions
# and naming reservations.  GCP Projects are long lived naming reservations.
# the cloud foundation toolkit addresses the naming collisions
# ---------------------------------------------------------------------------------------------------------------------
# development environment
module "project-factory" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 6.0"

  name                    = "iq9-dev-env"
  random_project_id       = "true"
  org_id                  = "${var.gcp_org_id}"
  billing_account         = "${var.gcp_org_billing_account}"
  usage_bucket_name       = "iq9-dev-env-usage-reporting-bucket"
  usage_bucket_prefix     = "iq9/dev"
  default_service_account = "keep"
}

