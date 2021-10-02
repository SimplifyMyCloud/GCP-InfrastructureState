# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Provider
# ---------------------------------------------------------------------------------------------------------------------
provider "google" {
  region      = "us-west1"
  credentials = file("~/.config/gcloud/terraform-root-sa-key.json")

}

provider "google-beta" {
  region      = "us-west1"
  credentials = file("~/.config/gcloud/terraform-root-sa-key.json")
}
