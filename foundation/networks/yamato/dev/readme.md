# Foundation Layer — yamato / dev VPC

The single, deliberately small VPC inside `iq9-gcp-dev-yamato`. One project, one VPC — no Shared VPC, no host/service split. Dev is meant to empower fast iteration; the multi-project networking model that prod will use would add daily friction (cross-project IAM, host-project quotas, two states to apply per change) for zero developer-velocity benefit at this scale.

For the broader design philosophy — hardcoded values, state granularity, and change-control posture — see [`docs/infrastructurestate.md`](../../../../docs/infrastructurestate.md).

## What this state owns

Four resources, all inside `iq9-gcp-dev-yamato` (the APIs this state needs — `compute`, `servicenetworking` — are enabled by `foundation/gcp-projects/yamato/dev/`):

1. `iq9-vpc-dev-yamato` — the VPC (custom-mode, REGIONAL routing)
2. `iq9-subnet-dev-yamato` — the only subnet, `10.10.0.0/20` in us-west1 (Oregon)
3. `iq9-psa-dev-yamato` — Private Service Access range, `10.20.0.0/20`
4. The PSA peering connection to `servicenetworking.googleapis.com`

What this state does *not* own (deferred to Service Layer):

- Serverless VPC Access connector — created when Cloud Run lands
- Cloud NAT / Cloud Router — not needed; Cloud Run egresses direct-to-internet for public traffic, and only private RFC1918 targets route via VPC
- Firewall rules — not needed; we have no GCE VMs to SSH into, and GCP's stateful firewall handles Cloud Run → Cloud SQL return traffic without explicit rules
- Cloud SQL, Cloud Run, GKE, anything else — Service Layer concerns

## Region

us-west1, The Dalles, Oregon. Matches the bootstrap region and the provider default in `../../../../gcp_provider.tf`. Runner VM, state bucket, this VPC, and any service-layer compute all live on the same continental side of the planet so latency stays sane and egress charges stay regional.

## CIDR plan

```
10.10.0.0/20    subnet for primary workloads          (4096 addresses)
10.10.16.0/28   Serverless VPC Access connector       (16 addresses, reserved by service layer when CR lands)
10.20.0.0/20    PSA range for service producers        (4096 addresses, peered to Cloud SQL et al)
```

These three ranges don't overlap, leaving plenty of room for future subnets (GKE secondary ranges, additional connectors, internal LB proxy-only subnets) without renumbering.

## Hardcoded values

| Field | Value | Rationale |
| --- | --- | --- |
| `project` (everywhere) | `iq9-gcp-dev-yamato` | The project owns the VPC |
| `region` | `us-west1` | Oregon — matches every other foundation resource |
| Subnet CIDR | `10.10.0.0/20` | RFC1918, disjoint from PSA range |
| PSA CIDR | `10.20.0.0/20` (`prefix_length = 20`, `address = "10.20.0.0"`) | RFC1918, /20 leaves headroom for multiple service producers |
| `routing_mode` | `REGIONAL` | Single-region environment |
| `private_ip_google_access` | `true` | Workloads without external IPs reach Google APIs over Google's network, not via NAT |
| `auto_create_subnetworks` | `false` | Custom mode — every subnet is explicit |
| Peering `deletion_policy` | `ABANDON` | Tearing down peering would strand Cloud SQL and other private-IP service producers |

## Files in this directory

| File | Purpose |
| --- | --- |
| `networks_yamato_dev.tf` | The 6 resources, hardcoded, heavily commented |
| `networks_yamato_dev_gcs_backend.tf` | TF state at `gs://iq9-iac-ops-tf-state-bucket/terraform/state/foundation/networks/yamato/dev/` |
| `gcp_provider.tf` | Soft link to repo-root `gcp_provider.tf` |
| `readme.md` | This file |

## First-time setup

```bash
cd foundation/networks/yamato/dev/

terraform init

terraform plan   # 6 resources to create
terraform apply
```

The APIs this state needs (`compute`, `servicenetworking`) are enabled by the gcp-projects foundation state — apply that first. Total runtime is usually 1-3 minutes (the `google_service_networking_connection` peering is the long pole — ~60-90s).

After the apply, verify:

```bash
gcloud compute networks describe iq9-vpc-dev-yamato \
  --project=iq9-gcp-dev-yamato \
  --format='table(name, autoCreateSubnetworks, routingConfig.routingMode)'

gcloud compute networks subnets describe iq9-subnet-dev-yamato \
  --region=us-west1 \
  --project=iq9-gcp-dev-yamato \
  --format='table(name, ipCidrRange, region.basename(), privateIpGoogleAccess)'

gcloud services vpc-peerings list \
  --network=iq9-vpc-dev-yamato \
  --project=iq9-gcp-dev-yamato
```

Expected:

- VPC: `autoCreateSubnetworks = False`, `routingConfig.routingMode = REGIONAL`
- Subnet: `ipCidrRange = 10.10.0.0/20`, `region = us-west1`, `privateIpGoogleAccess = True`
- Peering: one connection to `servicenetworking.googleapis.com` using the `iq9-psa-dev-yamato` range

## Subsequent runs

```bash
cd foundation/networks/yamato/dev/
terraform init
terraform plan   # steady state — should report "No changes."
```

If a `plan` ever shows drift, something has changed by hand and the audit log is the next stop.

## What comes next

Once this VPC exists, the Service Layer states for yamato can land:

1. `service/yamato/dev/cloudsql/` — Cloud SQL Postgres with private IP from the PSA range
2. `service/yamato/dev/cloudrun/` — Cloud Run service + Serverless VPC Access connector consuming `10.10.16.0/28`, plus the runtime SA and Secret Manager bindings

Both consume this VPC by name; neither modifies it.
