provider "google" {
  credentials = "${file("~/.config/gcloud/terraform-admin.json")}"
  project     = "theorum"
  region      = "us-west1"
}

terraform {
 backend "gcs" {
   bucket  = "smc-theorum-terraform-state-files"
   prefix    = "/terraform.tfstate"
   project = "theorum"
 }
}