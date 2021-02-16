# GCP Project - Production Environment IaC

GCP Project named `iq9-production` hosted in the GCP Folder named `production`.

This is the production development environment for iq9.

Terraform will be run in this directory, creating a Terraform state containing:

* GCP Project `iq9-production`


Directory contents:

* `gcp_folders.tf` - contains all GCP Folders desired state
* `gcp_providers.tf` - soft Linux link back to the root Terraform providers file
* `gcs_backend.tf` - Terraform state file located in `terraform/state/foundation/gcp_folders`

Terraform State File stored in a GCS Bucket:

`gs://iq9-terraform-shared-state-bucket/terraform/state/foundation/gcp_projects/production_env`