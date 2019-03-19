provider "google" {
  credentials = "${file("~/.config/gcloud/terraform-admin.json")}"
  project     = "simplifymycloud-dev"
  region      = "us-west1"
}

terraform {
 backend "gcs" {
   bucket  = "smc-terraform-state-files-dev"
   prefix    = "/terraform_state_dev.tfstate"
   project = "simplifymycloud-dev"
 }
}