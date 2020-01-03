# ---------------------------------------------------------------------------------------------------------------------
# vars to ensure the state of the foundation layer
# ---------------------------------------------------------------------------------------------------------------------
# set the GCP Organization ID for the Foundation Layer
variable "gcp_org_id" {
  type    = string
}

# set the GCP Organization Billing Account for the Foundation Layer
variable "gcp_org_billing_account" {
  type    = string
}

# set the Terraform Foundation Layer GCP Service Account
# Cloud Foundation Toolkit requires this explict
variable "gcp_foundation_layer_tf_sa_json" {
  type    = string
}