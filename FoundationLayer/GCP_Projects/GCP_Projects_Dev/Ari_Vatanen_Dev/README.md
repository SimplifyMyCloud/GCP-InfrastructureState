# GCP Project - Dev Environment IaC

GCP Project named `iq9-dev` hosted in the GCP Folder named `dev`.

This is the development environment for iq9.

Terraform will be run in this directory, creating a Terraform state containing:

* GCP Project `iq9-dev`
* GCP network `iq9-dev-network`
* GCP subnetworks `iq9-dev-network-subnet-01`, `iq9-dev-network-subnet-02`, `iq9-dev-network-subnet-03`

Directory contents:

* `gcp_folders.tf` - contains all GCP Folders desired state
* `gcp_providers.tf` - soft Linux link back to the root Terraform providers file
* `gcs_backend.tf` - Terraform state file located in `terraform/state/foundation/gcp_folders`

Terraform State File stored in a GCS Bucket:

`gs://iq9-terraform-shared-state-bucket/terraform/state/foundation/gcp_projects/dev_env`