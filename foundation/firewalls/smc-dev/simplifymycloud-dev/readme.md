# firewalls/smc-dev/simplifymycloud-dev

Terraform for project **`simplifymycloud-dev`** in folder `smc-dev` (`922883963214`): VPC firewall rules (and Cloud Armor policies).

| | |
| --- | --- |
| GCP node | project **`simplifymycloud-dev`** in folder `smc-dev` (`922883963214`) |
| Terraform state | `gs://smc-ops-tf-state/terraform/state/foundation/firewalls/smc-dev/simplifymycloud-dev/default.tfstate` |
| Imported | 2026-11-01/02 from the live Org, 6 resources, zero-diff plan |

## Resources

| Terraform type | Count |
| --- | --- |
| `google_compute_firewall` | 6 |

## Files

| File | What it holds |
| --- | --- |
| `firewalls_simplifymycloud_dev_firewalls.tf` | firewall rules and Cloud Armor |
| `firewalls_simplifymycloud_dev_gcs_backend.tf` | this directory's state location (hardcoded) |
| `gcp_provider.tf` | symlink to the repo-root `gcp_provider.tf` (Terraform + provider versions) |

Each resource's `import {}` block sits right under it. After the first apply they are no-ops, kept as a record of where each resource came from.

## Run it

```bash
cd foundation/firewalls/smc-dev/simplifymycloud-dev
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=smc-tf-foundation-sa@smc-ops.iam.gserviceaccount.com
export GOOGLE_BACKEND_IMPERSONATE_SERVICE_ACCOUNT=$GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
terraform init && terraform plan   # expected: No changes
```

## Findings (imported as-is, fix in a later PR)

- `default-allow-http` allows **tcp:80** from **0.0.0.0/0** (the whole internet)
- `default-allow-https` allows **tcp:443** from **0.0.0.0/0** (the whole internet)
- `smc-fw-public-22` allows **tcp:22** from **0.0.0.0/0** (the whole internet)
