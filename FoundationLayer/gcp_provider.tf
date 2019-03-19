provider "google" {
  credentials = "${file("~/.config/gcloud/terraform-admin.json")}"
  project     = "${var.gcp_project}"
  region      = "${var.gcp_region}"
}

terraform {
 backend "gcs" {
   bucket  = "smc-theorum-terraform-state-files"
   prefix    = "/terraform_state_${var.gcp_environment}.tfstate"
   project = "${var.gcp_project}"
 }
}