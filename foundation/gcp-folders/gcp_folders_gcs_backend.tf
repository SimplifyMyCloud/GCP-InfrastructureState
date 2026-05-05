# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Folders — Terraform State (GCS backend)
# ---------------------------------------------------------------------------------------------------------------------
#
# State for this directory's resources lives in:
#   gs://iq9-iac-ops-tf-state-bucket/terraform/state/foundation/gcp-folders/
#
# The bucket is in iq9-ops-iac, has uniform bucket-level access on, public
# access prevention enforced, and versioning enabled. Object access is
# restricted to iq9-tf-foundation-sa via roles/storage.objectAdmin granted
# at bucket scope.

terraform {
  backend "gcs" {
    bucket                      = "iq9-iac-ops-tf-state-bucket"
    prefix                      = "terraform/state/foundation/gcp-folders"
    impersonate_service_account = "iq9-tf-foundation-sa@iq9-ops-iac.iam.gserviceaccount.com"
  }
}