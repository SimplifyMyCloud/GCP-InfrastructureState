<!-- hand-written -->
# foundation/firewalls

VPC firewall rules (and Cloud Armor policies, none today), one directory per project with a VPC. Firewall rules live apart from their networks so rule changes, the frequent and risky ones, get their own small state and review.

⚠️ The prod `default` VPCs still carry Google's original `default-allow-ssh` / `default-allow-rdp` / `default-allow-icmp` rules **open to 0.0.0.0/0**. They were imported as-is; tightening them is the first hardening PR.

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
