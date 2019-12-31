terraform {
  backend "gcs" {
    bucket = "iq9-tf-bootstrap"
    prefix = "terraform/state"
  }
}
