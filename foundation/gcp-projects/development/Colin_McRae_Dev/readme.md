# Foundation Layer - GCP Projects - Development - Colin McRae

GCP Project named `colin_mcrae_dev_tf` hosted in the GCP Folder named `FoundationLayer/GCP_Projects_Dev/Colin_McRae_Dev`.

This is the development environment for Ari Vatanen hosted in the iq9 GCP Org.

Terraform will be run in this directory, creating a Terraform state containing:

* GCP Project `colin_mcrae_dev_tf`
* GCP network `default`
* GCP subnetworks `default`

Directory contents:

* `gcp_projects_dev_colin_mcrae.tf` - contains the desired state for the GCP Project
* `gcp_providers.tf` - soft Linux link back to the root Terraform providers file
* `gcs_backend.tf` - Terraform state file located in `terraform/state/foundation/gcp_projects/dev_env/colin_mcrae_dev`

Terraform State File stored in a GCS Bucket:

`gs://iq9-terraform-shared-state-bucket/terraform/state/foundation/gcp_projects/dev_env/colin_mcrae_dev`