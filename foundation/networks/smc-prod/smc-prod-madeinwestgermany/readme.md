# networks/smc-prod/smc-prod-madeinwestgermany

Terraform for project **`smc-prod-madeinwestgermany`** in folder `smc-prod` (`386439801809`): VPC networks, subnets, routers.

| | |
| --- | --- |
| GCP node | project **`smc-prod-madeinwestgermany`** in folder `smc-prod` (`386439801809`) |
| Terraform state | `gs://smc-ops-tf-state/terraform/state/foundation/networks/smc-prod/smc-prod-madeinwestgermany/default.tfstate` |
| Imported | 2026-11-01/02 from the live Org, 1 resources, zero-diff plan |

## Resources

| Terraform type | Count |
| --- | --- |
| `google_compute_network` | 1 |

## Files

| File | What it holds |
| --- | --- |
| `gcp_provider.tf` | symlink to the repo-root `gcp_provider.tf` (Terraform + provider versions) |
| `networks_smc_prod_madeinwestgermany_gcs_backend.tf` | this directory's state location (hardcoded) |
| `networks_smc_prod_madeinwestgermany_network.tf` | VPC networks |

Each resource's `import {}` block sits right under it. After the first apply they are no-ops, kept as a record of where each resource came from.

## Run it

```bash
cd foundation/networks/smc-prod/smc-prod-madeinwestgermany
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=smc-tf-foundation-sa@smc-ops.iam.gserviceaccount.com
export GOOGLE_BACKEND_IMPERSONATE_SERVICE_ACCOUNT=$GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
terraform init && terraform plan   # expected: No changes
```
