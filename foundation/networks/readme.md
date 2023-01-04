# Foundation Layer - GCP Networks

GCP Networks contain the host VPC networks for the environments, dev, test, stage, and production. GCP Networks are long lived, permanent GCP assets.  Because of this fact, the Terraform for the GCP Networks should be hard coded with no variables.  

Terraform will be run in this directory, creating a Terraform state containing just the GCP Networks desired state.

Directory contents:

* `gcp_vpc_host_{environment}.tf` - contains all GCP Networks Host VPC desired state for that environment.
* `gcp_providers.tf` - soft Linux link back to the root Terraform providers file
* `gcs_backend.tf` - Terraform state file located in `terraform/state/foundation/gcp_networks/vpc_host_{environment}/`

Terraform State File stored in a GCS Bucket:

`gs://iq9-tf-states/terraform/state/foundation/gcp_folders`
