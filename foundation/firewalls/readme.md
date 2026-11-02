<!-- hand-written -->
# foundation/firewalls

VPC firewall rules (and Cloud Armor policies, none today), one directory per project with a VPC. Firewall rules live apart from their networks so rule changes, the frequent and risky ones, get their own small state and review.

✅ **No SSH or RDP from the internet anywhere** (2026-11-02). Google's `default-allow-ssh` / `default-allow-rdp` were deleted from the 5 prod VPCs, and `smc-fw-public-22` from dev. Dev SSH is IAP-only (`smc-fw-iap-22`, source `35.235.240.0/20`): `gcloud compute ssh <vm> --tunnel-through-iap`. The prod VPCs have no VMs; whoever adds one adds an IAP-only SSH rule in the same PR. `default-allow-icmp` from 0.0.0.0/0 was kept on purpose (ping/path-MTU).

State for any directory below: `gs://smc-ops-tf-state/terraform/state/foundation/firewalls/<same path>/default.tfstate`.

| Directory | Terraform for |
| --- | --- |
| [`smc-dev/simplifymycloud-dev/`](smc-dev/simplifymycloud-dev/) | project `simplifymycloud-dev` |
| [`smc-prod/smc-prod-bigbarkozspeedshop/`](smc-prod/smc-prod-bigbarkozspeedshop/) | project `smc-prod-bigbarkozspeedshop` |
| [`smc-prod/smc-prod-caballerosflyingclub/`](smc-prod/smc-prod-caballerosflyingclub/) | project `smc-prod-caballerosflyingclub` |
| [`smc-prod/smc-prod-madeinwestgermany/`](smc-prod/smc-prod-madeinwestgermany/) | project `smc-prod-madeinwestgermany` |
| [`smc-prod/smc-prod-simplifymycloud/`](smc-prod/smc-prod-simplifymycloud/) | project `smc-prod-simplifymycloud` |
| [`smc-prod/smc-prod-trilliumhiring/`](smc-prod/smc-prod-trilliumhiring/) | project `smc-prod-trilliumhiring` |

Back to the [Foundation guide](../readme.md).
