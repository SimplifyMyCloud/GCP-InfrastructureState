# GCP Folders IaC

GCP Folders contain environments, dev, test, stage, and production. GCP Folders are long lived, permanent GCP assets.  Because of this fact, the Terraform for the GCP Folders should be hard coded with no variables.  

Terraform will be run in this directory, creating a Terraform state containing just the GCP Folders desired state.

Directory contents:

* `gcp_folders.tf` - contains all GCP Folders desired state
* `gcp_providers.tf` - soft Linux link back to the root Terraform providers file
* `gcs_backend.tf` - Terraform state file located in `terraform/state/foundation/gcp_folders`
