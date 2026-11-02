# firewalls/smc-prod/smc-prod-trilliumhiring

Terraform for project **`smc-prod-trilliumhiring`** in folder `smc-prod` (`386439801809`): VPC firewall rules (and Cloud Armor policies).

| | |
| --- | --- |
| GCP node | project **`smc-prod-trilliumhiring`** in folder `smc-prod` (`386439801809`) |
| Terraform state | `gs://smc-ops-tf-state/terraform/state/foundation/firewalls/smc-prod/smc-prod-trilliumhiring/default.tfstate` |
| Imported | 2026-11-01/02 from the live Org, 2 resources, zero-diff plan |

## Resources

| Terraform type | Count |
| --- | --- |
| `google_compute_firewall` | 2 |

## Files

| File | What it holds |
| --- | --- |
| `firewalls_smc_prod_trilliumhiring_firewalls.tf` | firewall rules and Cloud Armor |
| `firewalls_smc_prod_trilliumhiring_gcs_backend.tf` | this directory's state location (hardcoded) |
| `gcp_provider.tf` | symlink to the repo-root `gcp_provider.tf` (Terraform + provider versions) |

Each resource's `import {}` block sits right under it. After the first apply they are no-ops, kept as a record of where each resource came from.

## Run it

```bash
cd foundation/firewalls/smc-prod/smc-prod-trilliumhiring
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=smc-tf-foundation-sa@smc-ops.iam.gserviceaccount.com
export GOOGLE_BACKEND_IMPERSONATE_SERVICE_ACCOUNT=$GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
terraform init && terraform plan   # expected: No changes
```

## Findings (imported as-is, fix in a later PR)

- `default-allow-icmp` allows **icmp** from **0.0.0.0/0** (the whole internet)
