<!-- hand-written -->
# foundation/iam

Who can do what. `iam/gcp-org/` holds org-level grants, the 3 custom roles, the org audit config and the Terraform SA's grants (plan-only, plus the change-window switch; see `foundation/readme.md` section 4). `iam/<env>/` holds folder-level grants (inherited by every project in that folder). `iam/<env>/<project>/` holds the project's service accounts and project-level grants. Every grant is a `google_*_iam_member` (additive): Terraform owns exactly the listed grants.

State for any directory below: `gs://smc-ops-tf-state/terraform/state/foundation/iam/<same path>/default.tfstate`.

| Directory | Terraform for |
| --- | --- |
| [`smc-prod/`](smc-prod/) | the `smc-prod` folder itself |
| [`smc-ops/`](smc-ops/) | the `smc-ops` folder itself |
| [`gcp-org/`](gcp-org/) | the Org |
| [`smc-dev/simplifymycloud-dev/`](smc-dev/simplifymycloud-dev/) | project `simplifymycloud-dev` |
| [`smc-ops/smc-ops/`](smc-ops/smc-ops/) | project `smc-ops` |
| [`smc-prod/smc-dental-knox/`](smc-prod/smc-dental-knox/) | project `smc-dental-knox` |
| [`smc-prod/smc-prod-bbmrc/`](smc-prod/smc-prod-bbmrc/) | project `smc-prod-bbmrc` |
| [`smc-prod/smc-prod-bigbarkozspeedshop/`](smc-prod/smc-prod-bigbarkozspeedshop/) | project `smc-prod-bigbarkozspeedshop` |
| [`smc-prod/smc-prod-caballerosflyingclub/`](smc-prod/smc-prod-caballerosflyingclub/) | project `smc-prod-caballerosflyingclub` |
| [`smc-prod/smc-prod-madeinwestgermany/`](smc-prod/smc-prod-madeinwestgermany/) | project `smc-prod-madeinwestgermany` |
| [`smc-prod/smc-prod-olympic-flying-club/`](smc-prod/smc-prod-olympic-flying-club/) | project `smc-prod-olympic-flying-club` |
| [`smc-prod/smc-prod-psmtherapy/`](smc-prod/smc-prod-psmtherapy/) | project `smc-prod-psmtherapy` |
| [`smc-prod/smc-prod-simplifymycloud/`](smc-prod/smc-prod-simplifymycloud/) | project `smc-prod-simplifymycloud` |
| [`smc-prod/smc-prod-trilliumhiring/`](smc-prod/smc-prod-trilliumhiring/) | project `smc-prod-trilliumhiring` |

Back to the [Foundation guide](../readme.md).
