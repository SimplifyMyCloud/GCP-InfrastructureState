# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Provider
# ---------------------------------------------------------------------------------------------------------------------
provider "google" {
  region      = "us-west1"
  credentials = file("~/.config/gcloud/iq9-ops-7523-a0f4e1dbaa27.json")

}

provider "google-beta" {
  region      = "us-west1"
  credentials = file("~/.config/gcloud/iq9-ops-7523-a0f4e1dbaa27.json")
}
