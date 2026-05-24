# Foundation Layer — bakery VPC

The dedicated, deliberately tiny VPC that hosts the **ephemeral build VMs** Packer
spins up in the [GCE Bakery](../../gce-bakery/). Shared by every bakery recipe
([`gamilas-redteam/`](../../gce-bakery/gamilas-redteam/), `gitlab-offline/`, …) and
intentionally separate from any application VPC.

**Why its own network?** An image-build VM is privileged (installs software as root),
internet-pulling, and short-lived — and the bakery is a **supply-chain chokepoint**:
poison one baked image and every VM downstream inherits it. Isolating the forge keeps a
compromise *during a bake* off the app's wire. The bakery also practices what the
security demo preaches:

- build VMs get **no external IP** — Packer's inbound SSH arrives over an **IAP tunnel**, so there's zero public attack surface on the box;
- outbound (apt/go/git to install the toolkit) leaves through a **Cloud NAT** — one controlled, logged egress IP.

> **Home project caveat:** lives in `iq9-gcp-dev-yamato` for now. The eventual home is a
> dedicated ops/bakery project (e.g. `iq9-gcp-ops-01`); migrating is a project-string
> change on these resources + the Packer `gcp_project_id` var. Nothing else moves.

## What this state owns

| # | Resource | Name |
| --- | --- | --- |
| 1 | `google_compute_network` | `iq9-vpc-bakery-us-we1` (custom-mode, REGIONAL) |
| 2 | `google_compute_subnetwork` | `iq9-subnet-bakery-build` — `10.50.0.0/24` in us-west1, PGA on |
| 3 | `google_compute_router` | `iq9-rtr-bakery-us-we1` |
| 4 | `google_compute_router_nat` | `iq9-nat-bakery-us-we1` (AUTO_ONLY, all ranges) |
| 5 | `google_compute_firewall` | `iq9-fw-bakery-ssh-iap-build-tcp-22-allow` — IAP range → tcp:22, tag `bakery-build` |

## Region & CIDR

us-west1 (Oregon) — we do everything in us-west1. The baked **image is global**, so
region only governs where the throwaway build VM runs.

```
10.50.0.0/24   bakery build subnet   (256 addresses; one ephemeral VM at a time)
```

Disjoint from the yamato VPC (`10.10.0.0/20`, `10.20.0.0/20`) so the two could be peered
later without renumbering.

## Hardcoded values

| Field | Value | Rationale |
| --- | --- | --- |
| `project` (everywhere) | `iq9-gcp-dev-yamato` | Bakery's home for now (see caveat) |
| `region` | `us-west1` | Oregon — everything lives here |
| Subnet CIDR | `10.50.0.0/24` | RFC1918, disjoint from the yamato ranges |
| `private_ip_google_access` | `true` | No-external-IP build VM reaches Google APIs without NAT |
| NAT IP allocation | `AUTO_ONLY` | Google-managed egress IP; no reserved address to manage |
| Firewall source | `35.235.240.0/20` | The fixed IAP TCP-forwarding range — the *only* ingress |
| Firewall target tag | `bakery-build` | Set by the Packer source's `var.gcp_network_tags` |

## First-time setup

```bash
cd foundation/networks/bakery/
terraform init
terraform plan    # 5 resources to create
terraform apply
```

The APIs this state needs (`compute`) are enabled by the gcp-projects foundation state —
apply that first. Runtime is ~1-2 minutes.

Verify:

```bash
gcloud compute networks describe iq9-vpc-bakery-us-we1 \
  --project=iq9-gcp-dev-yamato \
  --format='table(name, autoCreateSubnetworks, routingConfig.routingMode)'

gcloud compute routers nats describe iq9-nat-bakery-us-we1 \
  --router=iq9-rtr-bakery-us-we1 --region=us-west1 --project=iq9-gcp-dev-yamato \
  --format='table(name, natIpAllocateOption, sourceSubnetworkIpRangesToNat)'

gcloud compute firewall-rules describe iq9-fw-bakery-ssh-iap-build-tcp-22-allow \
  --project=iq9-gcp-dev-yamato \
  --format='table(name, sourceRanges.list(), targetTags.list(), allowed[].map().firewall_rule().list())'
```

## Subsequent runs

```bash
terraform plan    # steady state — should report "No changes."
```

If a `plan` ever shows drift, something changed by hand — the audit log is the next stop.

## Consumed by

[`../../gce-bakery/gamilas-redteam/`](../../gce-bakery/gamilas-redteam/) — the Packer
recipe defaults `gcp_network=iq9-vpc-bakery-us-we1`,
`gcp_subnetwork=iq9-subnet-bakery-build`, tags the build VM `bakery-build`, and builds
with no external IP over IAP.

## Files in this directory

| File | Purpose |
| --- | --- |
| `networks_bakery.tf` | The 5 resources, hardcoded, heavily commented |
| `networks_bakery_gcs_backend.tf` | TF state at `gs://iq9-iac-ops-tf-state-bucket/terraform/state/foundation/networks/bakery/` |
| `gcp_provider.tf` | Soft link to repo-root `gcp_provider.tf` |
| `readme.md` | This file |
