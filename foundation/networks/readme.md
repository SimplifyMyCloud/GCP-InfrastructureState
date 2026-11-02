<!-- hand-written -->
# foundation/networks

VPC networks, subnets and routers, one directory per project that HAS a VPC. Today that is 6 projects, each with an auto-mode `default` VPC and no peering, Shared VPC or hybrid links. Auto-mode subnets belong to the network and aren't separate resources. See the networking whiteboard in [`../readme.md`](../readme.md#3-whiteboard-2--networking).

State for any directory below: `gs://smc-ops-tf-state/terraform/state/foundation/networks/<same path>/default.tfstate`.

| Directory | Terraform for |
| --- | --- |
| [`smc-dev/simplifymycloud-dev/`](smc-dev/simplifymycloud-dev/) | project `simplifymycloud-dev` |
| [`smc-prod/smc-prod-bigbarkozspeedshop/`](smc-prod/smc-prod-bigbarkozspeedshop/) | project `smc-prod-bigbarkozspeedshop` |
| [`smc-prod/smc-prod-caballerosflyingclub/`](smc-prod/smc-prod-caballerosflyingclub/) | project `smc-prod-caballerosflyingclub` |
| [`smc-prod/smc-prod-madeinwestgermany/`](smc-prod/smc-prod-madeinwestgermany/) | project `smc-prod-madeinwestgermany` |
| [`smc-prod/smc-prod-simplifymycloud/`](smc-prod/smc-prod-simplifymycloud/) | project `smc-prod-simplifymycloud` |
| [`smc-prod/smc-prod-trilliumhiring/`](smc-prod/smc-prod-trilliumhiring/) | project `smc-prod-trilliumhiring` |

Back to the [Foundation guide](../readme.md).
