# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Provider
# ---------------------------------------------------------------------------------------------------------------------
provider "google" {
  #credentials = "file(tf-foundation-sa.json)"
  region      = "us-west1"
  version     = "~> 2.18.1"
}

provider "google-beta" {
  #credentials = "file(tf-foundation-sa.json)"
  version     = "~> 2.18.1"
}

provider "null" {
  version = "~> 2.1"
}

provider "random" {
  version = "~> 2.2"
}
