# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Bootstrap to prepare for Terraform IaC ensured state
# ---------------------------------------------------------------------------------------------------------------------

module "bootstrap" {
  source  = "terraform-google-modules/bootstrap/google//modules/cloudbuild"
  version = "~> 0.1"

  org_id                  = "${var.gcp_org_id}"
  billing_account         = "${var.gcp_org_billing_account}"
  group_org_admins        = "${var.gcp_org_group_org_admins}"
  default_region          = "${var.gcp_org_default_region}"
  terraform_sa_email      = "${var.gcp_org_terraform_sa_email}"
  terraform_sa_name       = "${var.gcp_org_terraform_sa_name}"
  terraform_state_bucket  = "${var.gcp_org_bootstrap_bucket}"
}
