# ---------------------------------------------------------------------------------------------------------------------
# vars to ensure the state of the foundation layer
# ---------------------------------------------------------------------------------------------------------------------
# set the GCP Organization ID for the Foundation Layer
variable "gcp_org_id" {
  type    = string
  default = "447686549950"
}

# set the GCP Org prefix
variable "gcp_org_project_prefix" {
  type = string
  default = "iq9"
}

# set the GCP Organization Billing Account for the Foundation Layer
variable "gcp_org_billing_account" {
  type    = string
  default = "01AE65-A7583F-D9EB1A"
}

# set the GCP default region
variable "gcp_org_default_region" {
  type    = string
  default = "us-west1"
}

# set the Terraform Foundation Layer GCP Service Account
# Cloud Foundation Toolkit requires this explict
#variable "gcp_foundation_layer_tf_sa_json" {
#  type    = string
#  default = "~/.config/gcloud/tf-foundation-sa.json"
#}

variable "gcp_org_terraform_sa_email" {
  type    = string
  default = "tf-foundation-sa@iq9-tf-bootstrap.iam.gserviceaccount.com"
}

variable "gcp_org_terraform_sa_name" {
  type    = string
  default = "tf-foundation-sa"
}

variable "gcp_org_bootstrap_bucket" {
  type    = string
  default = "iq9-tf-state"
}


# set the various group orgs
variable "gcp_org_group_org_admins" {
  type    = string
  default = "gcp-org-admins@iq9.io"
}

variable "gcp_org_billing_admins_group" {
  type    = string
  default = "gcp-billing-admins@iq9.io"
}

# set the list of Cloud Source Repos to create
variable "gcp_csr_repo_list" {
  type = list(string)
  default = ["FoundationLayer", "ServiceLayer", "AppLayer"]
}

# set the list of GCP APIs to be enabled
variable "gcp_bootstrap_apis" {
  type = list(string)
  default = ["cloudresourcemanager.googleapis.com", "cloudbilling.googleapis.com", "iam.googleapis.com", "storage-api.googleapis.com", "serviceusage.googleapis.com", "cloudbuild.googleapis.com", "sourcerepo.googleapis.com", "cloudkms.googleapis.com"]
}

