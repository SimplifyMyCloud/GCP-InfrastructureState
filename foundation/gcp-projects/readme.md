<!-- hand-written -->
# foundation/gcp-projects

Every project in the Org, one directory per project, grouped by the folder it lives in. Each directory owns the `google_project` itself (folder, billing, deletion protection), its **enabled APIs** (a hardcoded list), and **every in-project service**: GCS buckets, Cloud DNS, Firebase / Firestore / security rules, App Engine, API keys, monitoring, KMS, BigQuery, Pub/Sub, Artifact Registry, Cloud Build. IAM, logging, networks and firewalls for the same project live in the sibling slices.

State for any directory below: `gs://smc-ops-tf-state/terraform/state/foundation/gcp-projects/<same path>/default.tfstate`.

| Directory | Terraform for |
| --- | --- |
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
