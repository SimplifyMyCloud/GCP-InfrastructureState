# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Provider
# ---------------------------------------------------------------------------------------------------------------------

provider "google" {
#  credentials = "${file("~/.config/gcloud/terraform-admin.json")}"
  project     = "simplifymycloud-dev"
  region      = "us-west1"
}
